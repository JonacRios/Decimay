import 'package:flutter/material.dart';

class PredictionResultWidget extends StatelessWidget {
  final String prediction;

  PredictionResultWidget({required this.prediction});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      padding: EdgeInsets.all(20),
      width: double.infinity,
      child: Align(
        alignment: Alignment.center,
        child: Text(
          prediction,
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
