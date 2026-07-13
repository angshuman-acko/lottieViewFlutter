import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Compact numeric field used by view sizing controls.
class NumericField extends StatelessWidget {
  const NumericField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.suffix,
    this.onChanged,
    this.allowDecimal = true,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? suffix;
  final ValueChanged<String>? onChanged;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              allowDecimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
            ),
          ],
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            isDense: true,
          ),
        ),
      ],
    );
  }
}
