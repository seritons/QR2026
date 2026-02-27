

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../menu_models.dart';
import '../menu_view.dart';

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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.name),
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
            decoration: InputDecoration(
              labelText: 'Miktar',
              suffixText: _unit.label,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal')),
        FilledButton(
          onPressed: () {
            final a = double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0;
            if (a <= 0) return;
            Navigator.pop(context, IngredientPickResult(amount: a, unit: _unit));
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}

