import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize:   28,
    fontWeight: FontWeight.bold,
    color:      AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize:   22,
    fontWeight: FontWeight.bold,
    color:      AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize:   18,
    fontWeight: FontWeight.w600,
    color:      AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color:    AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    color:    AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color:    AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize:   16,
    fontWeight: FontWeight.w600,
    color:      AppColors.textPrimary,
  );

  static const TextStyle amount = TextStyle(
    fontSize:    24,
    fontWeight:  FontWeight.bold,
    color:       AppColors.secondary,
    letterSpacing: 0.5,
  );
}