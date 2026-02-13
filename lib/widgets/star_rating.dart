import 'package:anidong/utils/app_colors.dart';
import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 18,
    this.color = AppColors.yellow400,
  });

  @override
  Widget build(BuildContext context) {
    // Rating is 0-10, we display 5 stars.
    final normalizedRating = rating / 2;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = normalizedRating - index;
        IconData icon;
        if (starValue >= 0.75) {
          icon = Icons.star;
        } else if (starValue >= 0.25) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }

        return Icon(
          icon,
          color: color,
          size: size,
        );
      }),
    );
  }
}
