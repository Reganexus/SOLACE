import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';

class Buttonstyle {
  static ButtonStyle gray = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    backgroundColor: AppColors.gray,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  static ButtonStyle darkgray = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    backgroundColor: AppColors.blackTransparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  static ButtonStyle neon = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    backgroundColor: AppColors.neon,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  static ButtonStyle red = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    backgroundColor: AppColors.red,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  static ButtonStyle buttonNeon = TextButton.styleFrom(
    backgroundColor: AppColors.neon,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  static ButtonStyle buttonRed = TextButton.styleFrom(
    backgroundColor: AppColors.red,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  static ButtonStyle buttonDarkBlue = TextButton.styleFrom(
    backgroundColor: AppColors.darkblue,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  static ButtonStyle buttonPurple = TextButton.styleFrom(
    backgroundColor: AppColors.purple,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  static ButtonStyle buttonBlue = TextButton.styleFrom(
    backgroundColor: AppColors.blue,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  static ButtonStyle buttonDarkGray = TextButton.styleFrom(
    backgroundColor: AppColors.blackTransparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  static ButtonStyle buttonGray = TextButton.styleFrom(
    backgroundColor: AppColors.darkerGray,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  static ButtonStyle buttonWhiteTransparent = TextButton.styleFrom(
    backgroundColor: AppColors.whiteTransparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  static ButtonStyle white = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    backgroundColor: AppColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: AppColors.darkgray),
    ),
  );
}
