import 'package:flutter/material.dart';

class AppBarWidget extends StatelessWidget {
  final String title;

  AppBarWidget({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[800],
      width: double.infinity,
      padding: EdgeInsets.all(20),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
