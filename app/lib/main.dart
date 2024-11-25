import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/live_prediction_page.dart';

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
      title: 'Predicción en Vivo con AFD',
      home: LivePredictionPage(camera: camera),
    );
  }
}
