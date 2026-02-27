import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../menu_models.dart';
import '../menu_view.dart';
import 'IngredientPickDialog.dart';
import 'IngredientQuickCreateDialog.dart';

class ProductEditorSheet extends StatefulWidget {
  final String title;
  final ProductModel initial;
  final List<IngredientLibraryItem> ingredientLibrary;

  /// ✅ Ekstra seçebilmek için: menüdeki tüm ürünler (candidate list)
  /// Not: initial ürünün kendisini filtreleyeceğiz.
  final List<ProductModel> allProducts;

  const ProductEditorSheet({
    super.key,
    required this.title,
    required this.initial,
    required this.ingredientLibrary,
    required this.allProducts,
  });

  @override
  State<ProductEditorSheet> createState() => _ProductEditorSheetState();
}

class _ProductEditorSheetState extends State<ProductEditorSheet> {
  late ProductModel _p;
  late List<IngredientLibraryItem> _lib;

  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;

  final TextEditingController _ingSearch = TextEditingController();
  String _q = '';

  // ✅ Extras arama
  final TextEditingController _extraSearch = TextEditingController();
  String _eq = '';

  String _tmpId() =>
      'tmp_${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(9999)}';

  @override
  void initState() {
    super.initState();
    _p = widget.initial;
    _lib = [...widget.ingredientLibrary];

    _name = TextEditingController(text: _p.name);
    _desc = TextEditingController(text: _p.description);
    _price = TextEditingController(
      text: _p.price.toStringAsFixed(2).replaceAll('.', ','),
    );

    _ingSearch.addListener(() => setState(() => _q = _ingSearch.text.trim()));
    _extraSearch.addListener(() => setState(() => _eq = _extraSearch.text.trim()));
  }

  @override
  void dispose() {
    _ingSearch.dispose();
    _extraSearch.dispose();
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    super.dispose();
  }

  Map<String, IngredientLibraryItem> get _libById =>
      {for (final i in _lib) i.id: i};

  List<IngredientLibraryItem> get _suggestions {
    if (_q.isEmpty) return const [];
    final q = _q.toLowerCase();
    return _lib.where((x) => x.name.toLowerCase().contains(q)).take(3).toList();
  }

  bool get _hasExactName {
    final q = _q.toLowerCase();
    return _lib.any((x) => x.name.toLowerCase() == q);
  }

  // ✅ Extras candidates (kendi ürününü çıkar)
  List<ProductModel> get _extraCandidates {
    final selfId = _p.id;
    final list = widget.allProducts.where((x) => x.id != selfId).toList();
    if (_eq.trim().isEmpty) return list;
    final q = _eq.trim().toLowerCase();
    return list.where((x) => x.name.toLowerCase().contains(q)).toList();
  }

  Map<String, ProductModel> get _productById =>
      {for (final p in widget.allProducts) p.id: p};

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                  FilledButton(onPressed: _commit, child: const Text('Kaydet')),
                ],
              ),

              const SizedBox(height: 12),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Ürün adı'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _desc,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (opsiyonel)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Fiyat',
                  hintText: '0,00',
                ),
              ),

              const SizedBox(height: 18),

              // ==========================================================
              // ✅ EXTRAS SECTION (UX: chips + add sheet + max qty quick edit)
              // ==========================================================
              _sectionHeader(
                t,
                title: 'Ekstralar',
                subtitle: 'Bu ürüne ek olarak alınabilecek ürünler (ör: Patates, Shot).',
                icon: Icons.extension_outlined,
                trailing: FilledButton.icon(
                  onPressed: _openExtrasPicker,
                  icon: const Icon(Icons.add),
                  label: const Text('Ekle'),
                ),
              ),
              const SizedBox(height: 10),

              if (_p.extras.isEmpty)
                _emptyHint(
                  t,
                  text: 'Ekstra yok. “Ekle” ile bu ürüne ekstra seçenekler ekleyebilirsin.',
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _p.extras.map((x) {
                    final prod = _productById[x.extraProductId];
                    final name = prod?.name ?? 'Ürün';
                    final price = prod?.price ?? 0.0;
                    final maxQty = x.maxQty;

                    return InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => _editExtraMaxQty(x),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: t.dividerColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_circle_outline, size: 18),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: t.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${price.toStringAsFixed(2).replaceAll('.', ',')} ₺ • max $maxQty',
                                  style: t.textTheme.bodySmall?.copyWith(
                                    color: t.hintColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Kaldır',
                              onPressed: () => _removeExtra(x.extraProductId),
                              icon: Icon(Icons.close, size: 18, color: t.hintColor),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 18),

              // ==========================================================
              // INGREDIENTS SECTION
              // ==========================================================
              _sectionHeader(
                t,
                title: 'İçerikler',
                subtitle: 'Ürünün içeriğini buradan yönet.',
                icon: Icons.format_list_bulleted,
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _ingSearch,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Örn: sucuk, yumurta, kaşar',
                ),
              ),
              if (_q.isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  child: Column(
                    children: [
                      ..._suggestions.map(
                            (it) => ListTile(
                          dense: true,
                          title: Text(it.name),
                          subtitle: Text(
                            '${it.unit.label}${(it.note ?? '').trim().isEmpty ? '' : ' · ${it.note}'}',
                          ),
                          onTap: () => _addIngredientFlow(existingItem: it),
                        ),
                      ),
                      if (_suggestions.isEmpty || !_hasExactName)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.add),
                          title: Text('"$_q" ekle'),
                          subtitle: const Text('Birim seçerek oluştur'),
                          onTap: _addNewIngredientFromQuery,
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              if (_p.ingredients.isEmpty)
                _emptyHint(t, text: 'Bu üründe içerik yok.')
              else
                ..._p.ingredients.map((ref) {
                  final it = _libById[ref.ingredientId];
                  final name = it?.name ?? 'Bilinmeyen içerik';
                  final unit = (ref.unitOverride ?? it?.unit ?? IngredientUnit.adet);

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: t.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Birim: ${unit.label}',
                                      style: t.textTheme.bodySmall
                                          ?.copyWith(color: t.hintColor),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeRef(ref),
                                icon: Icon(Icons.delete_outline,
                                    color: t.colorScheme.error),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: IngredientUnitOverrideField(
                                  label: 'Birim',
                                  initial: unit,
                                  onChanged: (v) {
                                    _setUnitOverride(ref, v);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 130,
                                child: TextFormField(
                                  initialValue: ref.amount
                                      .toStringAsFixed(0)
                                      .replaceAll('.', ','),
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Miktar',
                                    suffixText: unit.label,
                                  ),
                                  onChanged: (v) {
                                    final n =
                                    double.tryParse(v.replaceAll(',', '.'));
                                    if (n != null) _setAmount(ref, n);
                                  },
                                ),
                              ),
                            ],
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

  // ==========================================================
  // UI HELPERS
  // ==========================================================

  Widget _sectionHeader(
      ThemeData t, {
        required String title,
        required String subtitle,
        required IconData icon,
        Widget? trailing,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: t.colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: t.colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: t.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: t.textTheme.bodySmall?.copyWith(color: t.hintColor),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          trailing,
        ],
      ],
    );
  }

  Widget _emptyHint(ThemeData t, {required String text}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.dividerColor.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: t.hintColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: t.textTheme.bodySmall?.copyWith(color: t.hintColor),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // COMMIT
  // ==========================================================

  void _commit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;

    final price = double.tryParse(_price.text.replaceAll(',', '.')) ?? 0;

    // ✅ self reference guard: ürün kendini ekstra yapmasın
    final selfId = _p.id;
    final cleanedExtras = _p.extras
        .where((x) => x.extraProductId != selfId)
        .toList();

    final updated = _p.copyWith(
      name: name,
      description: _desc.text.trim(),
      price: price,
      extras: cleanedExtras,
    );

    Navigator.pop(
      context,
      ProductEditResult(product: updated, updatedLibrary: _lib),
    );
  }

  // ==========================================================
  // ✅ EXTRAS: PICKER + CRUD
  // ==========================================================

  Future<void> _openExtrasPicker() async {
    // UX: alttan sheet, arama + checkbox
    final picked = await showModalBottomSheet<List<ProductExtraRef>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExtrasPickerSheet(
        title: 'Ekstra seç',
        all: widget.allProducts.where((x) => x.id != _p.id).toList(),
        initial: _p.extras,
      ),
    );

    if (picked == null) return;

    setState(() {
      _p = _p.copyWith(extras: picked);
    });
  }

  Future<void> _editExtraMaxQty(ProductExtraRef ref) async {
    final txt = await _textDialog(
      'Max adet',
      hint: 'Örn: 1 / 2 / 3',
      initial: ref.maxQty.toString(),
    );
    if (txt == null) return;

    final v = int.tryParse(txt.trim());
    final safe = (v == null || v < 1) ? 1 : v;

    setState(() {
      _p = _p.copyWith(
        extras: _p.extras
            .map((x) => x.extraProductId == ref.extraProductId
            ? x.copyWith(maxQty: safe)
            : x)
            .toList(),
      );
    });
  }

  void _removeExtra(String extraProductId) {
    setState(() {
      _p = _p.copyWith(
        extras: _p.extras.where((x) => x.extraProductId != extraProductId).toList(),
      );
    });
  }

  // ------------------------------------------------------------
  // Add ingredient flow: ask amount + unit (ref override)
  // ------------------------------------------------------------

  Future<void> _addIngredientFlow({required IngredientLibraryItem existingItem}) async {
    if (_p.ingredients.any((x) => x.ingredientId == existingItem.id)) {
      _ingSearch.clear();
      return;
    }

    final picked = await showDialog<IngredientPickResult>(
      context: context,
      builder: (_) => IngredientPickDialog(
        name: existingItem.name,
        defaultUnit: existingItem.unit,
      ),
    );

    if (picked == null) return;

    setState(() {
      _p = _p.copyWith(
        ingredients: [
          ..._p.ingredients,
          ProductIngredientRef(
            ingredientId: existingItem.id,
            amount: picked.amount,
            unitOverride: picked.unit,
          ),
        ],
      );
      _ingSearch.clear();
    });
  }

  Future<void> _addNewIngredientFromQuery() async {
    final rawName = _q.trim();
    if (rawName.isEmpty) return;

    final already = _lib.firstWhere(
          (x) => x.name.toLowerCase() == rawName.toLowerCase(),
      orElse: () => const IngredientLibraryItem(
        id: '',
        name: '',
        unit: IngredientUnit.adet,
      ),
    );
    if (already.id.isNotEmpty) {
      await _addIngredientFlow(existingItem: already);
      return;
    }

    final created = await showDialog<IngredientLibraryItem>(
      context: context,
      builder: (_) => IngredientQuickCreateDialog(
        initialName: rawName,
        newId: _tmpId(),
      ),
    );

    if (created == null) return;

    setState(() {
      _lib = [..._lib, created];
    });

    await _addIngredientFlow(existingItem: created);
    _ingSearch.clear();
  }

  void _removeRef(ProductIngredientRef ref) {
    setState(() {
      _p = _p.copyWith(
        ingredients: _p.ingredients
            .where((x) => x.ingredientId != ref.ingredientId)
            .toList(),
      );
    });
  }

  void _setAmount(ProductIngredientRef ref, double amount) {
    setState(() {
      _p = _p.copyWith(
        ingredients: _p.ingredients
            .map((x) => x.ingredientId == ref.ingredientId
            ? x.copyWith(amount: amount)
            : x)
            .toList(),
      );
    });
  }

  void _setUnitOverride(ProductIngredientRef ref, IngredientUnit unit) {
    setState(() {
      _p = _p.copyWith(
        ingredients: _p.ingredients
            .map((x) => x.ingredientId == ref.ingredientId
            ? x.copyWith(unitOverride: unit)
            : x)
            .toList(),
      );
    });
  }

  // ==========================================================
  // Dialog helper (local)
  // ==========================================================

  Future<String?> _textDialog(
      String title, {
        required String hint,
        String initial = '',
      }) async {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Tamam')),
        ],
      ),
    );
  }
}

// ============================================================
// ✅ Extras Picker BottomSheet (arama + checkbox + max qty)
// ============================================================

class _ExtrasPickerSheet extends StatefulWidget {
  final String title;
  final List<ProductModel> all;
  final List<ProductExtraRef> initial;

  const _ExtrasPickerSheet({
    required this.title,
    required this.all,
    required this.initial,
  });

  @override
  State<_ExtrasPickerSheet> createState() => _ExtrasPickerSheetState();
}

class _ExtrasPickerSheetState extends State<_ExtrasPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _q = '';

  late Map<String, ProductExtraRef> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {for (final x in widget.initial) x.extraProductId: x};

    _search.addListener(() => setState(() => _q = _search.text.trim()));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ProductModel> get _filtered {
    if (_q.isEmpty) return widget.all;
    final q = _q.toLowerCase();
    return widget.all.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _editQty(String productId) async {
    final current = _selected[productId]?.maxQty ?? 1;
    final c = TextEditingController(text: current.toString());

    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Max adet'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Örn: 1 / 2 / 3'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(c.text.trim());
              Navigator.pop(ctx, (n == null || n < 1) ? 1 : n);
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );

    if (v == null) return;

    setState(() {
      final old = _selected[productId];
      _selected[productId] = (old == null)
          ? ProductExtraRef(
        extraProductId: productId,
        maxQty: v,
        sort: 0,
        extraProduct: null,
      )
          : old.copyWith(maxQty: v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return SafeArea(
      child: Material(
        color: t.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kapat'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final out = _selected.values.toList();
                      Navigator.pop(context, out);
                    },
                    child: const Text('Tamam'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Ekstra ürün ara',
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final p = _filtered[i];
                    final isOn = _selected.containsKey(p.id);
                    final maxQty = _selected[p.id]?.maxQty ?? 1;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Checkbox(
                          value: isOn,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selected[p.id] = ProductExtraRef(
                                  extraProductId: p.id,
                                  maxQty: 1,
                                  sort: 0,
                                  extraProduct: p, // UI cache
                                );
                              } else {
                                _selected.remove(p.id);
                              }
                            });
                          },
                        ),
                        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${p.price.toStringAsFixed(2).replaceAll(".", ",")} ₺'
                              '${isOn ? ' • max $maxQty' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isOn
                            ? IconButton(
                          tooltip: 'Max adet',
                          icon: const Icon(Icons.tune),
                          onPressed: () => _editQty(p.id),
                        )
                            : null,
                        onTap: () {
                          setState(() {
                            if (!isOn) {
                              _selected[p.id] = ProductExtraRef(
                                extraProductId: p.id,
                                maxQty: 1,
                                sort: 0,
                                extraProduct: p,
                              );
                            } else {
                              _selected.remove(p.id);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}