import 'package:flutter/material.dart';

/// Unified category color indicator used throughout the app.
///
/// Renders a soft tinted outer circle with a solid inner dot in the same
/// color. Pass [isSelected] to add a self-colored selection ring (used by
/// the color picker in the category edit sheet).
class CategoryColorIndicator extends StatelessWidget {
  final Color color;
  final double size;
  final bool isSelected;

  const CategoryColorIndicator({
    super.key,
    required this.color,
    this.size = 18,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final innerSize = size * 0.40;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: isSelected ? Border.all(color: color, width: 2.0) : null,
      ),
      child: Center(
        child: Container(
          width: innerSize,
          height: innerSize,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
