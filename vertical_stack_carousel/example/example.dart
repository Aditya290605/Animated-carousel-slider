// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:animated_carousel_slider/animated_carousel_slider.dart';

/// A minimal example app demonstrating AnimatedCarouselSlider usage.
///
/// To run:
/// ```bash
/// cd example
/// flutter run
/// ```
void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnimatedCarouselSlider Example',
      theme: ThemeData(useMaterial3: true),
      home: const ExamplePage(),
    );
  }
}

class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample card colors for visual distinction
    final colors = [
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.red.shade100,
      Colors.teal.shade100,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Carousel Slider Demo')),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: AnimatedCarouselSlider(
          onIndexChanged: (index) => print('Active card: $index'),
          items: List.generate(
            colors.length,
            (i) => _buildSampleCard(i, colors[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildSampleCard(int index, Color color) {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          'Card ${index + 1}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
