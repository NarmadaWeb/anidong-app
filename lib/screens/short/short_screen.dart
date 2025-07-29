import 'package:flutter/material.dart';

class ShortsScreen extends StatelessWidget {
  const ShortsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // PageView untuk swipe vertikal seperti di HTML
    return PageView(
      scrollDirection: Axis.vertical,
      children: [
        _buildShortsPage(Colors.black, "Shorts Video 1"),
        _buildShortsPage(Colors.deepPurple, "Shorts Video 2"),
        _buildShortsPage(Colors.teal, "Shorts Video 3"),
      ],
    );
  }

  Widget _buildShortsPage(Color color, String text) {
    return Container(
      color: color,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
