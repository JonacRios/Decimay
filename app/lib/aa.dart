import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  MyApp({required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Predicción en Vivo',
      home: LivePredictionPage(camera: camera),
    );
  }
}

class LivePredictionPage extends StatefulWidget {
  final CameraDescription camera;

  LivePredictionPage({required this.camera});

  @override
  _LivePredictionPageState createState() => _LivePredictionPageState();
}

class _LivePredictionPageState extends State<LivePredictionPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  String? _predictionResult;
  String serverIP = '192.168.20.87';
  String serverPort = '8000';

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();

    // Mostrar el mensaje de bienvenida
    Future.delayed(Duration.zero, () => _showWelcomeMessage());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Función para mostrar el mensaje de bienvenida
  void _showWelcomeMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Bienvenido a DECYMAL'),
          content: Text(
            '¡Bienvenido a DECYMAL! Esta aplicación móvil está diseñada para detectar números mayas utilizando un modelo de IA y Autómatas Finitos Deterministas (AFD). '
                'Actualmente, la aplicación puede reconocer hasta 30 números mayas. ¡Explora y experimenta con la tecnología avanzada que hemos integrado!',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _captureAndPredict() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      final prediction = await _uploadImage(File(image.path));
      if (prediction != null) {
        setState(() {
          _predictionResult = prediction;
        });
      } else {
        _showErrorDialog('No se pudo obtener la predicción.');
      }
    } catch (e) {
      _showErrorDialog('Error al capturar o enviar la imagen: $e');
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('http://$serverIP:$serverPort/upload/');
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final decodedResponse = json.decode(responseBody);
        return decodedResponse['prediction'].toString();
      } else {
        final responseBody = await response.stream.bytesToString();
        final decodedResponse = json.decode(responseBody);
        _showErrorDialog(decodedResponse['message'] ?? 'Error desconocido');
        return null;
      }
    } catch (e) {
      _showErrorDialog('Error al subir la imagen: $e');
      return null;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController ipController = TextEditingController(text: serverIP);
        TextEditingController portController = TextEditingController(text: serverPort);

        return AlertDialog(
          title: Text('Configuración del Servidor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ipController,
                decoration: InputDecoration(labelText: 'IP del Servidor'),
              ),
              TextField(
                controller: portController,
                decoration: InputDecoration(labelText: 'Puerto'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  serverIP = ipController.text;
                  serverPort = portController.text;
                });
                Navigator.of(context).pop();
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Título con tamaño más grande y texto "DECYMAL"
            Container(
              color: Colors.grey[800],
              width: double.infinity,
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'DECIMAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Vista previa de la cámara que ocupa todo el espacio disponible
            Expanded(
              child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return CameraPreview(_controller);
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
            // Resultado de la predicción, solo el número, centrado en la parte izquierda en área gris
            if (_predictionResult != null)
              Container(
                color: Colors.grey,  // Área gris
                padding: EdgeInsets.all(20),
                width: double.infinity,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    _predictionResult!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Menú inferior fijo
            Container(
              color: Colors.black.withOpacity(0.7),
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white),
                    onPressed: _showSettingsDialog,
                  ),
                  IconButton(
                    icon: Icon(Icons.camera, color: Colors.white, size: 30),
                    onPressed: _captureAndPredict,
                  ),
                  IconButton(
                    icon: Icon(Icons.info, color: Colors.white),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AboutDialog(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// About Dialog personalizado
class AboutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                color: Colors.red,
              ),
            ),
            Container(
              color: Colors.lightBlue[50], // Fondo azul claro para el "About"
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo a la izquierda y quien lo desarrolló a la derecha
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/android/logo_unillanos.png',
                        width: 50,
                        height: 50,
                      ),
                      SizedBox(width: 20),
                      // Descripción del autor
                      Expanded(
                        child: Text(
                          'Desarrollado por Jonathan Camilo Rios Silva',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Descripción del proyecto
                  Text(
                    'DECIMAY es una avanzada aplicación destinada al análisis de imágenes para el reconocimiento de números mayas, integrando dos enfoques tecnológicos clave: Redes Neuronales Artificiales (AFN) y Autómatas Finitos Deterministas (AFD), proporcionando una herramienta robusta y eficaz para el estudio de estos antiguos símbolos.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  SizedBox(height: 20),
                  // Detalles sobre la doctora y la universidad
                  Text(
                    'Desarrollado para el curso de Lenguajes de Programación, dirigido a Diana Marcela Cardona Román, PhD.\n\n',

                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ],

        ),
      ),
    );
  }
}
