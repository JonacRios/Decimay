import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../services/image_upload_service.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/prediction_result_widget.dart';
import '../utils/dialogs.dart';
import '../widgets/app_bar_widget.dart';
import '../models/afd_model.dart';

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
  String serverIP = '192.168.20.87'; // Dirección IP inicial
  String serverPort = '8000'; // Puerto inicial

  final AFDModel afdModel = AFDModel(); // Modelo del AFD

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
    afdModel.reset(); // Inicializa en el estado q0
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureAndPredict() async {
    try {
      await _initializeControllerFuture;

      setState(() {
        _predictionResult = "Esperando la predicción...";
      });

      final image = await _controller.takePicture();

      final prediction = await ImageUploadService.uploadImage(
        File(image.path),
        serverIP,
        serverPort,
      );

      if (prediction != null) {
        afdModel.processInput("valid");
        setState(() {
          _predictionResult = "Número Maya detectado correctamente: ${prediction.toString()}";
        });
        await _showPredictionPopup(prediction.toString());
        afdModel.processInput("valid");
        setState(() {
          _predictionResult = "Proceso completado. Estado Final alcanzado.";
        });
      } else {
        Dialogs.showErrorDialog(context, 'No se pudo obtener la predicción.');
      }
    } catch (e) {
      Dialogs.showErrorDialog(context, 'Error al capturar o enviar la imagen: $e');
    }
  }

  Future<void> _showPredictionPopup(String prediction) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Resultado de la predicción'),
          content: Text('Número Maya detectado: $prediction'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  // Función para mostrar el diálogo de configuración
  void _showConfigDialog() {
    final TextEditingController ipController = TextEditingController(text: serverIP);
    final TextEditingController portController = TextEditingController(text: serverPort);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Configuración del servidor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ipController,
                decoration: InputDecoration(labelText: 'IP del servidor'),
              ),
              TextField(
                controller: portController,
                decoration: InputDecoration(labelText: 'Puerto del servidor'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Guardar'),
              onPressed: () {
                setState(() {
                  serverIP = ipController.text;
                  serverPort = portController.text;
                });
                Navigator.of(context).pop();
                print('Nueva configuración: IP=$serverIP, Puerto=$serverPort');
              },
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Botón de cierre
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: Colors.red,
                  ),
                ),
                Container(
                  color: Colors.lightBlue[50], // Fondo azul claro
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo y autor
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/android/logo_unillanos.png',
                            width: 50,
                            height: 50,
                          ),
                          SizedBox(width: 20),
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
                      // Descripción de la app
                      Text(
                        'DECIMAY es una avanzada aplicación destinada al análisis de imágenes para el reconocimiento de números mayas, integrando dos enfoques tecnológicos clave: Redes Neuronales Artificiales (AFN) y Autómatas Finitos Deterministas (AFD), proporcionando una herramienta robusta y eficaz para el estudio de estos antiguos símbolos.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(height: 20),
                      // Información del curso
                      Text(
                        'Desarrollado para el curso de Lenguajes de Programación, dirigido a Diana Marcela Cardona Román, PhD.',
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppBarWidget(title: 'DECIMAY'),
            Expanded(
              child: CameraPreviewWidget(
                controllerFuture: _initializeControllerFuture,
                cameraController: _controller,
              ),
            ),
            if (_predictionResult != null)
              PredictionResultWidget(prediction: _predictionResult!), // Mostrar predicción
            Container(
              color: Colors.black.withOpacity(0.7),
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white),
                    onPressed: _showConfigDialog, // Botón de configuración
                  ),
                  IconButton(
                    icon: Icon(Icons.camera, color: Colors.white, size: 30),
                    onPressed: _captureAndPredict, // Botón de predicción
                  ),
                  IconButton(
                    icon: Icon(Icons.info, color: Colors.white),
                    onPressed: _showInfoDialog, // Botón de información
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
