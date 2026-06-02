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
    final isAnime = currentMode == 'anime';

    return GestureDetector(
      onTap: () {
        onModeChanged(isAnime ? 'donghua' : 'anime');
      },
      child: Container(
        width: 135,
        height: 36,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: isAnime ? 0 : (135 - 8) / 2, // Adjusted for 135 width and 4 padding
              top: 0,
              bottom: 0,
              child: Container(
                width: 63, // Half of 135 minus some padding
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Anime',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isAnime
                            ? AppColors.primaryText
                            : AppColors.secondaryText,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Donghua',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isAnime
                            ? AppColors.secondaryText
                            : AppColors.primaryText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
