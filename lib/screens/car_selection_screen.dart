// lib/screens/car_selection_screen.dart
import 'package:flutter/material.dart';

class CarSelectionScreen extends StatelessWidget {
  const CarSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Car')),
      body: const Center(child: Text('Car selection placeholder')),
    );
  }
}
