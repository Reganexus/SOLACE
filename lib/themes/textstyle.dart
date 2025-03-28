import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';

class Textstyle {
  static TextStyle title = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.bold,
    fontSize: 30,
    color: AppColors.black,
  );

  static TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: 'Inter',
    color: AppColors.black,
  );

  static TextStyle subheader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    fontFamily: 'Inter',
    color: AppColors.black,
  );

  static TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    fontFamily: 'Inter',
    color: AppColors.black,
    decoration: null,
  );

  static TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    fontFamily: 'Inter',
    color: AppColors.black,
    decoration: null,
  );

  static TextStyle bodySuperSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    fontFamily: 'Inter',
    color: AppColors.blackTransparent,
    decoration: null,
  );

  static TextStyle bodyWhite = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    fontFamily: 'Inter',
    color: AppColors.white,
    decoration: null,
  );

  static TextStyle bodyNeon = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    fontFamily: 'Inter',
    color: AppColors.neon,
  );

  static TextStyle bodyPurple = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    fontFamily: 'Inter',
    color: AppColors.purple,
  );

  static TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Inter',
    color: AppColors.gray,
  );

  static TextStyle error = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    fontFamily: 'Inter',
    color: AppColors.red,
  );

  static TextStyle largeButton = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: AppColors.white,
  );

  static TextStyle smallButton = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.bold,
    fontSize: 14,
    color: AppColors.white,
  );
}
