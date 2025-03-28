import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';

class Loader {
  static CircularProgressIndicator loaderWhite = CircularProgressIndicator(
    color: AppColors.white,
    strokeWidth: 4.0,
  );

  static CircularProgressIndicator loaderNeon = CircularProgressIndicator(
    color: AppColors.neon,
    strokeWidth: 4.0,
  );

  static CircularProgressIndicator loaderPurple = CircularProgressIndicator(
    color: AppColors.purple,
    strokeWidth: 4.0,
  );
}
