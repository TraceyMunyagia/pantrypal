import 'package:flutter/material.dart';

class IngredientChip extends StatelessWidget {
  const IngredientChip({
    required this.label,
    required this.onDeleted,
    super.key,
  });

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: const Color(0xFFFFEDD5),
      side: const BorderSide(color: Color(0xFFFDBA74)),
      deleteIconColor: const Color(0xFFEA580C),
      onDeleted: onDeleted,
      labelStyle: const TextStyle(
        color: Color(0xFF9A3412),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
