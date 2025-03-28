import 'package:flutter/material.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final List<String> messages;

  const ErrorDialog({required this.title, required this.messages, super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      title: Text(title, style: Textstyle.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            messages
                .map(
                  (message) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(message, style: Textstyle.error),
                  ),
                )
                .toList(),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: Buttonstyle.neon,
          child: Text('OK', style: Textstyle.smallButton),
        ),
      ],
    );
  }
}
