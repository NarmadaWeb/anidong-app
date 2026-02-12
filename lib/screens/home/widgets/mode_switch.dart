// lib/screens/home/widgets/mode_switch.dart

import 'package:anidong/utils/app_colors.dart';
import 'package:flutter/material.dart';

class ModeSwitch extends StatelessWidget {
  final String currentMode;
  final ValueChanged<String> onModeChanged;

  const ModeSwitch({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    bool isAnime = currentMode == 'anime';

    return Center(
      child: GestureDetector(
        onTap: () {
          onModeChanged(isAnime ? 'donghua' : 'anime');
        },
        child: Container(
          width: 150,
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                alignment: isAnime ? Alignment.centerLeft : Alignment.centerRight,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Container(
                  width: 75,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Row(
                children: [
                  _buildModeText('Anime', isAnime),
                  _buildModeText('Donghua', !isAnime),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeText(String text, bool isActive) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? AppColors.primaryText : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }
}
