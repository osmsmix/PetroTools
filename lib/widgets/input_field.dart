import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Numeric input field with a label and a unit suffix, shared by all tools.
class AppInputField extends StatelessWidget {
  final String label;
  final String unit;
  final TextEditingController controller;
  final String? helperText;

  const AppInputField({
    super.key,
    required this.label,
    required this.unit,
    required this.controller,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        helperText: helperText,
      ),
      validator: (value) {
        final parsed = double.tryParse(value ?? '');
        if (parsed == null) return 'Enter a number';
        if (parsed < 0) return 'Must be positive';
        return null;
      },
    );
  }
}
