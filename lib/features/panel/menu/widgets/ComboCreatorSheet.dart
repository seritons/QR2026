import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/tokens.dart';
import '../menu_models.dart';

class ComboCreatorSheet extends StatefulWidget {
  final String title;
  final List<ProductModel> products;

  const ComboCreatorSheet({
    super.key,
    required this.title,
    required this.products,
  });

  @override
  State<ComboCreatorSheet> createState() => _ComboCreatorSheetState();
}

class _ComboCreatorSheetState extends State<ComboCreatorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _note;
  late final TextEditingController _fixedPrice;

  final Uuid _uuid = const Uuid();

  ComboPriceMode _mode = ComboPriceMode.auto;
  final Map<String, int> _selected = {}; // productId -> qty

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _note = TextEditingController();
    _fixedPrice = TextEditingController(text: '0,00');

    _name.addListener(() => setState(() {}));
    _fixedPrice.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _fixedPrice.dispose();
    super.dispose();
  }

  List<ComboItemDraft> get _items {
    return _selected.entries.map((e) {
      final p = widget.products.firstWhere((x) => x.id == e.key);
      return ComboItemDraft(
        productId: p.id,
        name: p.name,
        unitPrice: p.price,
        qty: e.value,
      );
    }).toList();
  }

  double get _autoPrice =>
      _items.fold<double>(0, (a, x) => a + x.unitPrice * x.qty);

  double get _fixedPriceValue =>
      double.tryParse(_fixedPrice.text.replaceAll(',', '.')) ?? 0;

  bool get _canCommit {
    final hasName = _name.text.trim().isNotEmpty;
    final hasItems = _items.isNotEmpty;

    if (!hasName || !hasItems) return false;

    if (_mode == ComboPriceMode.fixed) {
      return _fixedPriceValue >= 0;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final finalPrice =
    _mode == ComboPriceMode.fixed ? _fixedPriceValue : _autoPrice;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.65,
        maxChildSize: 0.95,
        builder: (_, controller) => Material(
          color: t.colorScheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.rLg),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: tokens.divider,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTypography.title.copyWith(
                        color: tokens.text,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Kapat',
                      style: AppTypography.bodyStrong.copyWith(
                        color: tokens.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _canCommit ? _commit : null,
                    child: Text(
                      'Oluştur',
                      style: AppTypography.button.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                style: AppTypography.body.copyWith(
                  color: tokens.text,
                ),
                decoration: InputDecoration(
                  labelText: 'Paket adı',
                  labelStyle: AppTypography.body.copyWith(
                    color: tokens.muted,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                style: AppTypography.body.copyWith(
                  color: tokens.text,
                ),
                decoration: InputDecoration(
                  labelText: 'Not (opsiyonel)',
                  labelStyle: AppTypography.body.copyWith(
                    color: tokens.muted,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Fiyat',
                style: AppTypography.bodyStrong.copyWith(
                  color: tokens.text,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ComboPriceMode>(
                segments: [
                  ButtonSegment(
                    value: ComboPriceMode.auto,
                    label: Text(
                      'Oto',
                      style: AppTypography.caption.copyWith(
                        color: tokens.text,
                      ),
                    ),
                    icon: const Icon(Icons.auto_awesome),
                  ),
                  ButtonSegment(
                    value: ComboPriceMode.fixed,
                    label: Text(
                      'Sabit',
                      style: AppTypography.caption.copyWith(
                        color: tokens.text,
                      ),
                    ),
                    icon: const Icon(Icons.price_change),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
              const SizedBox(height: 10),
              if (_mode == ComboPriceMode.fixed)
                TextField(
                  controller: _fixedPrice,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.body.copyWith(
                    color: tokens.text,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Sabit fiyat',
                    hintText: '0,00',
                    labelStyle: AppTypography.body.copyWith(
                      color: tokens.muted,
                    ),
                    hintStyle: AppTypography.body.copyWith(
                      color: tokens.muted,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Oto: ${_autoPrice.toStringAsFixed(2).replaceAll('.', ',')} ₺',
                          style: AppTypography.bodyStrong.copyWith(
                            color: tokens.text,
                          ),
                        ),
                      ),
                      Text(
                        'Final: ${finalPrice.toStringAsFixed(2).replaceAll('.', ',')} ₺',
                        style: AppTypography.bodyStrong.copyWith(
                          color: tokens.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Ürün seç',
                style: AppTypography.bodyStrong.copyWith(
                  color: tokens.text,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.products.isEmpty)
                _emptyHint(context, 'Bu menüde ürün yok. Önce ürün oluşturmalısın.')
              else
                ...widget.products.map((p) {
                  final qty = _selected[p.id] ?? 0;

                  return Card(
                    elevation: 0,
                    child: ListTile(
                      title: Text(
                        p.name,
                        style: AppTypography.bodyStrong.copyWith(
                          color: tokens.text,
                        ),
                      ),
                      subtitle: Text(
                        '${p.price.toStringAsFixed(2).replaceAll('.', ',')} ₺',
                        style: AppTypography.caption.copyWith(
                          color: tokens.muted,
                        ),
                      ),
                      trailing: qty == 0
                          ? FilledButton(
                        onPressed: () => setState(() => _selected[p.id] = 1),
                        child: Text(
                          'Ekle',
                          style: AppTypography.button.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      )
                          : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => setState(() {
                              final next = qty - 1;
                              if (next <= 0) {
                                _selected.remove(p.id);
                              } else {
                                _selected[p.id] = next;
                              }
                            }),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$qty',
                            style: AppTypography.title.copyWith(
                              color: tokens.text,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => _selected[p.id] = qty + 1),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  void _commit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    if (_items.isEmpty) return;

    final fixed =
    double.tryParse(_fixedPrice.text.replaceAll(',', '.'));

    if (_mode == ComboPriceMode.fixed && (fixed == null || fixed < 0)) {
      return;
    }

    Navigator.pop(
      context,
      ComboDraft(
        id: _uuid.v4(),
        name: name,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        priceMode: _mode,
        fixedPrice: (_mode == ComboPriceMode.fixed) ? fixed : null,
        items: _items,
      ),
    );
  }

  Widget _emptyHint(BuildContext context, String text) {
    final t = Theme.of(context);
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(tokens.rMd),
        border: Border.all(
          color: t.dividerColor.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: tokens.muted, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(
                color: tokens.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}