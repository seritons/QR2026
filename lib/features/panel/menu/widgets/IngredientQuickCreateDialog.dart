

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../menu_models.dart';
import '../menu_view.dart';

class IngredientQuickCreateDialog extends StatefulWidget {
  final String initialName;
  final String newId;

  const IngredientQuickCreateDialog({
    super.key,
    required this.initialName,
    required this.newId,
  });

  @override
  State<IngredientQuickCreateDialog> createState() =>
      _IngredientQuickCreateDialogState();
}

class _IngredientQuickCreateDialogState extends State<IngredientQuickCreateDialog> {
  late final TextEditingController _name;
  late final TextEditingController _note;

  IngredientUnit _unit = IngredientUnit.adet;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _note = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('İçerik oluştur'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'İçerik adı'),
          ),
          const SizedBox(height: 12),
          IngredientUnitOverrideField(
            label: 'Birim',
            initial: _unit,
            onChanged: (v) => setState(() => _unit = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Not (opsiyonel)',
              hintText: 'örn: L boy, organik',
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
            final name = _name.text.trim();
            if (name.isEmpty) return;

            Navigator.pop(
              context,
              IngredientLibraryItem(
                id: widget.newId,
                name: name,
                unit: _unit,
                note: _note.text.trim().isEmpty ? null : _note.text.trim(),
              ),
            );
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}
