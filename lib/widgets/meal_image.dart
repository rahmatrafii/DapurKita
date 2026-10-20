import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../models/meal.dart';

class MealImage extends StatelessWidget {
  const MealImage({super.key, required this.meal, this.width, this.height});
  final Meal meal;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) => Image.network(
    meal.imageUrl,
    width: width,
    height: height,
    fit: BoxFit.cover,
    semanticLabel: 'Foto ${meal.name}',
    frameBuilder: (context, child, frame, synchronous) =>
        frame != null || synchronous
        ? child
        : const ColoredBox(
            color: pale,
            child: Center(child: Icon(Icons.restaurant_outlined, color: ink)),
          ),
    errorBuilder: (_, _, _) => SizedBox(
      width: width,
      height: height,
      child: const ColoredBox(
        color: pale,
        child: Center(
          child: Icon(Icons.restaurant_outlined, color: ink, size: 36),
        ),
      ),
    ),
  );
}
