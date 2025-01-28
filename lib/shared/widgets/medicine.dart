import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';

class Medicine extends StatelessWidget {
  const Medicine({super.key, required this.currentUserId});
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Medicine'),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: Text("medicine"),
    );
  }
}
