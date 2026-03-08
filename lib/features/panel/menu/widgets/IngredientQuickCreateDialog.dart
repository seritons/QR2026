import 'package:flutter/material.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/tokens.dart';
import '../menu_models.dart';
import 'ProductEditorSheet.dart';

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
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return AlertDialog(
      title: Text(
        'İçerik oluştur',
        style: AppTypography.title.copyWith(
          color: tokens.text,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            style: AppTypography.body.copyWith(
              color: tokens.text,
            ),
            decoration: InputDecoration(
              labelText: 'İçerik adı',
              labelStyle: AppTypography.body.copyWith(
                color: tokens.muted,
              ),
            ),
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
            style: AppTypography.body.copyWith(
              color: tokens.text,
            ),
            decoration: InputDecoration(
              labelText: 'Not (opsiyonel)',
              hintText: 'örn: L boy, organik',
              labelStyle: AppTypography.body.copyWith(
                color: tokens.muted,
              ),
              hintStyle: AppTypography.body.copyWith(
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