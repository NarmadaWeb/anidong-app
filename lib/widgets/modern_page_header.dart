import 'package:flutter/material.dart';
import 'package:anidong/utils/app_colors.dart';

class ModernPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const ModernPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0), // padding: 1rem 1rem 1.5rem
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 24.0), // margin: 0 -1rem 1.5rem
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.orangeAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24.0)), // border-radius: 0 0 1.5rem 1.5rem
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22, // text-2xl
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 4), // mb-1
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14, // text-sm
              color: AppColors.primaryText.withOpacity(0.8), // text-white/80
            ),
          ),
        ],
      ),
    );
  }
}
