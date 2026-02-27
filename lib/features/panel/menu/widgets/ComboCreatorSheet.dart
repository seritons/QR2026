import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

  ComboPriceMode _mode = ComboPriceMode.auto;
  final Map<String, int> _selected = {}; // productId -> qty

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _note = TextEditingController();
    _fixedPrice = TextEditingController(text: '0,00');
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _fixedPrice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final items = _selected.entries.map((e) {
      final p = widget.products.firstWhere((x) => x.id == e.key);
      return ComboItemDraft(
        productId: p.id,
        name: p.name,
        unitPrice: p.price,
        qty: e.value,
      );
    }).toList();

    final autoPrice = items.fold<double>(0, (a, x) => a + x.unitPrice * x.qty);
    final fixedPrice =
        double.tryParse(_fixedPrice.text.replaceAll(',', '.')) ?? 0;
    final finalPrice = _mode == ComboPriceMode.fixed ? fixedPrice : autoPrice;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.65,
        maxChildSize: 0.95,
        builder: (_, controller) => Material(
          color: t.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: t.dividerColor,
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
                      style: t.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kapat'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: (_name.text.trim().isEmpty || items.isEmpty)
                        ? null
                        : _commit,
                    child: const Text('Oluştur'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _name,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Paket adı'),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _note,
                decoration: const InputDecoration(
                  labelText: 'Not (opsiyonel)',
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Fiyat',
                style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),

              SegmentedButton<ComboPriceMode>(
                segments: const [
                  ButtonSegment(
                    value: ComboPriceMode.auto,
                    label: Text('Oto'),
                    icon: Icon(Icons.auto_awesome),
                  ),
                  ButtonSegment(
                    value: ComboPriceMode.fixed,
                    label: Text('Sabit'),
                    icon: Icon(Icons.price_change),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),

              const SizedBox(height: 10),
              if (_mode == ComboPriceMode.fixed)
                TextField(
                  controller: _fixedPrice,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sabit fiyat',
                    hintText: '0,00',
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
                          'Oto: ${autoPrice.toStringAsFixed(2).replaceAll('.', ',')} ₺',
                          style: t.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        'Final: ${finalPrice.toStringAsFixed(2).replaceAll('.', ',')} ₺',
                        style: t.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              Text(
                'Ürün seç',
                style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),

              ...widget.products.map((p) {
                final qty = _selected[p.id] ?? 0;
                return Card(
                  elevation: 0,
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text('${p.price.toStringAsFixed(2).replaceAll('.', ',')} ₺'),
                    trailing: qty == 0
                        ? FilledButton(
                      onPressed: () => setState(() => _selected[p.id] = 1),
                      child: const Text('Ekle'),
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
                        Text('$qty', style: t.textTheme.titleMedium),
                        IconButton(
                          onPressed: () => setState(() => _selected[p.id] = qty + 1),
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

    final items = _selected.entries.map((e) {
      final p = widget.products.firstWhere((x) => x.id == e.key);
      return ComboItemDraft(
        productId: p.id,
        name: p.name,
        unitPrice: p.price,
        qty: e.value,
      );
    }).toList();

    if (items.isEmpty) return;

    final fixed =
    double.tryParse(_fixedPrice.text.replaceAll(',', '.'));

    Navigator.pop(
      context,
      ComboDraft(
        id: 'tmp_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        priceMode: _mode,
        fixedPrice: (_mode == ComboPriceMode.fixed) ? (fixed ?? 0) : null,
        items: items,
      ),
    );
  }
}