import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textstyle.dart';

class LoaderScreen extends StatelessWidget {
  final String message;

  const LoaderScreen({super.key, this.message = "Loading... Please wait"});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Loader.loaderNeon,
            const SizedBox(height: 20),
            Text(message, style: Textstyle.body),
          ],
        ),
      ),
    );
  }
}
