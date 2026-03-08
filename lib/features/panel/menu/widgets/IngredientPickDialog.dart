import 'package:flutter/material.dart';

import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/tokens.dart';
import '../menu_models.dart';
import 'ProductEditorSheet.dart';

class IngredientPickDialog extends StatefulWidget {
  final String name;
  final IngredientUnit defaultUnit;

  const IngredientPickDialog({
    super.key,
    required this.name,
    required this.defaultUnit,
  });

  @override
  State<IngredientPickDialog> createState() => _IngredientPickDialogState();
}

class _IngredientPickDialogState extends State<IngredientPickDialog> {
  late final TextEditingController _amount;
  late IngredientUnit _unit;

  @override
  void initState() {
    super.initState();
    _unit = widget.defaultUnit;
    _amount = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return AlertDialog(
      title: Text(
        widget.name,
        style: AppTypography.title.copyWith(
          color: tokens.text,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IngredientUnitOverrideField(
            label: 'Birim',
            initial: _unit,
            onChanged: (v) => setState(() => _unit = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            style: AppTypography.body.copyWith(
              color: tokens.text,
            ),
            decoration: InputDecoration(
              labelText: 'Miktar',
              labelStyle: AppTypography.body.copyWith(
                color: tokens.muted,
              ),
              suffixText: _unit.label,
              suffixStyle: AppTypography.bodyStrong.copyWith(
                color: tokens.muted,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'İptal',
            style: AppTypography.bodyStrong.copyWith(
              color: tokens.muted,
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            final a = double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0;
            if (a <= 0) return;
            Navigator.pop(
              context,
              IngredientPickResult(amount: a, unit: _unit),
            );
          },
          child: Text(
            'Ekle',
            style: AppTypography.button.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}