import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPreviewWidget extends StatelessWidget {
  final Future<void> controllerFuture;
  final CameraController cameraController;

  CameraPreviewWidget({
    required this.controllerFuture,
    required this.cameraController,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: controllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return CameraPreview(cameraController);
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
