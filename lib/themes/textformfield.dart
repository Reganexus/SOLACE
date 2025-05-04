import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String labelText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.labelText,
    required this.enabled,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.maxLines,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      readOnly: readOnly,
      enabled: enabled,
      onTap: onTap,
      onChanged: onChanged,
      style: Textstyle.body,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: AppColors.gray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.neon, width: 2),
        ),
        labelStyle: Textstyle.body.copyWith(
          color: focusNode.hasFocus ? AppColors.neon : AppColors.black,
        ),
      ),
      validator: validator,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
    );
  }
}
