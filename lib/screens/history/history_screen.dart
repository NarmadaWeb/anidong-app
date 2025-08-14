import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/glass_card.dart';
import 'package:anidong/widgets/modern_page_header.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ModernPageHeader(
              title: '⏰ Watch History',
              subtitle: 'Continue where you left off',
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GlassCard(
                    child: Text(
                      'Content for history page goes here.',
                      style: TextStyle(color: AppColors.primaryText),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
