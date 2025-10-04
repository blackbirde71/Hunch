// hunches.dart
import 'package:flutter/material.dart';

class HunchesScreen extends StatelessWidget {
  const HunchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          'Hunches',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}