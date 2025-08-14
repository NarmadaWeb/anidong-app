import 'package:anidong/utils/app_colors.dart';
import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.surface,
      ),
      body: Center(
        child: Text(
          '$title Page',
          style: const TextStyle(color: AppColors.primaryText, fontSize: 24),
        ),
      ),
    );
  }
}
