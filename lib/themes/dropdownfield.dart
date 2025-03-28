import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';

class CustomDropdownField<T> extends StatelessWidget {
  final T? value;
  final FocusNode focusNode;
  final String labelText;
  final List<T> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final String Function(T) displayItem;

  const CustomDropdownField({
    super.key,
    required this.value,
    required this.focusNode,
    required this.labelText,
    required this.items,
    required this.onChanged,
    this.validator,
    required this.displayItem,
    required bool enabled,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      focusNode: focusNode,
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
        labelStyle: TextStyle(
          fontSize: 16,
          fontFamily: 'Inter',
          fontWeight: FontWeight.normal,
          color: focusNode.hasFocus ? AppColors.neon : AppColors.black,
        ),
      ),
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'Inter',
        fontWeight: FontWeight.normal,
        color: AppColors.black,
      ),
      items:
          items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(displayItem(item)),
            );
          }).toList(),
      onChanged: onChanged,
      validator: validator,
      dropdownColor: AppColors.white,
    );
  }
}
