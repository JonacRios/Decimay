import torch
import torch.nn as nn
from torchvision import transforms, models
from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from PIL import Image
import io

# Definir el modelo
class NeuronalNetwork(nn.Module):
    def __init__(self, num_classes, lstm_hidden, lstm_layers):
        super(NeuronalNetwork, self).__init__()
        resnet = models.resnet50(weights=models.ResNet50_Weights.DEFAULT)
        self.resnet = nn.Sequential(*list(resnet.children())[:-1])  # Quitar la capa final
        self.lstm = nn.LSTM(2048, lstm_hidden, lstm_layers, batch_first=True)
        self.fc = nn.Linear(lstm_hidden, num_classes)  # La salida del modelo es num_classes

    def forward(self, x):
        featueres = self.resnet(x)  # Extraemos características de ResNet
        featueres = featueres.view(featueres.size(0), -1)  # Aplanamos las características
        featueres = featueres.unsqueeze(1)  # Añadimos una dimensión para LSTM

        lstm_out, (hn, cn) = self.lstm(featueres)  # LSTM para procesar las características
        out = self.fc(hn[-1])  # La salida final pasa por la capa densa
        return out

# Configuración de dispositivo
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# Cargar el modelo
model = NeuronalNetwork(num_classes=31, lstm_hidden=128, lstm_layers=2).to(device)
model.load_state_dict(torch.load("model_max_state.pth", map_location=device, weights_only=True))

model.eval()  # Establecer el modelo en modo de evaluación

# Definir las transformaciones para la imagen de entrada
transform = transforms.Compose([
    transforms.Resize((224, 224)),  # Redimensionar la imagen
    transforms.ToTensor(),  # Convertir la imagen a tensor
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])  # Normalizar
])

# Crear la aplicación FastAPI
app = FastAPI()

# Definimos los estados como una clase para manejar las transiciones
class ImagePredictionProcess:
    def __init__(self):
        self.state = 1  # Estado inicial

    def next_state(self, valid=True):
        """
        Cambia el estado basado en la validez del paso.
        Si valid=True, pasa al siguiente estado. Si invalid=True, va al estado de error.
        """
        if valid:
            if self.state == 1:
                self.state = 2  # Estado 2: Procesar imagen
            elif self.state == 2:
                self.state = 3  # Estado 3: Predicción
            elif self.state == 3:
                self.state = 4  # Estado 4: Devolver respuesta
        else:
            self.state = 5  # Estado 5: Error

    def current_state(self):
        return self.state

@app.post("/upload/")
async def predict(file: UploadFile = File(...)):
    process = ImagePredictionProcess()

    # Estado 1: Esperar la imagen
    try:
        # Leer la imagen
        image_bytes = await file.read()
        pil_image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        
        # Transición al siguiente estado (Procesamiento)
        process.next_state(valid=True)  # Imagen cargada correctamente
        
    except Exception as e:
        # En caso de error, va al estado de error
        process.next_state(valid=False)  # Falla la carga de imagen
        return JSONResponse(content={"error": str(e), "message": "Hubo un problema con la carga de la imagen"}, status_code=500)

    # Estado 2: Procesamiento de la imagen
    try:
        input_tensor = transform(pil_image).unsqueeze(0)  
        input_tensor = input_tensor.to(device)  # Enviar a la GPU si está disponible

        # Transición al siguiente estado (Predicción)
        process.next_state(valid=True)  # Imagen procesada correctamente
        
    except Exception as e:
        # En caso de error, va al estado de error
        process.next_state(valid=False)  # Falla el procesamiento de imagen
        return JSONResponse(content={"error": str(e), "message": "Hubo un problema al procesar la imagen"}, status_code=500)

    # Estado 3: Realizar la predicción
    try:
        with torch.no_grad():  # No calcular gradientes durante la predicción
            output = model(input_tensor)
            prediction = torch.argmax(output, 1).item()  # Obtener la clase predicha
        
        # Transición al siguiente estado (Devolver respuesta)
        process.next_state(valid=True)  # Predicción realizada correctamente
        
    except Exception as e:
        # En caso de error, va al estado de error
        process.next_state(valid=False)  # Falla la predicción
        return JSONResponse(content={"error": str(e), "message": "Hubo un problema con la predicción"}, status_code=500)

    # Estado 4: Devolver respuesta
    try:
        # Devolver la respuesta con la predicción
        return JSONResponse(content={"prediction": prediction, "message": "Predicción exitosa"})
    
    except Exception as e:
        # En caso de error, va al estado de error
        process.next_state(valid=False)  # Falla al devolver la respuesta
        return JSONResponse(content={"error": str(e), "message": "Hubo un problema al devolver la respuesta"}, status_code=500)

    # Estado 5: Manejo de errores
    # Este estado es alcanzado si algo falla en cualquier paso
    return JSONResponse(content={"message": "Proceso terminado con errores"}, status_code=500)
