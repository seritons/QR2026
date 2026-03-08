import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/tokens.dart';
import '../menu_models.dart';
import '../menu_models.dart' as pick_dialog;
import 'IngredientPickDialog.dart' as pick_dialog;
import 'IngredientQuickCreateDialog.dart' as quick_dialog;

class ProductEditorSheet extends StatefulWidget {
  final String title;
  final ProductModel initial;
  final List<IngredientLibraryItem> ingredientLibrary;

  const ProductEditorSheet({
    super.key,
    required this.title,
    required this.initial,
    required this.ingredientLibrary,
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
  final Uuid _uuid = const Uuid();

  String _q = '';

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
  }

  @override
  void dispose() {
    _ingSearch.dispose();
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    super.dispose();
  }

  Map<String, IngredientLibraryItem> get _libById => {
    for (final i in _lib) i.id: i,
  };

  List<IngredientLibraryItem> get _suggestions {
    if (_q.isEmpty) return const [];
    final q = _q.toLowerCase();
    return _lib.where((x) => x.name.toLowerCase().contains(q)).take(3).toList();
  }

  bool get _hasExactName {
    final q = _q.toLowerCase();
    return _lib.any((x) => x.name.toLowerCase() == q);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                    onPressed: _commit,
                    child: Text(
                      'Kaydet',
                      style: AppTypography.button.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // BASIC
              TextField(
                controller: _name,
                style: AppTypography.body.copyWith(
                  color: tokens.text,
                ),
                decoration: InputDecoration(
                  labelText: 'Ürün adı',
                  labelStyle: AppTypography.body.copyWith(
                    color: tokens.muted,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _desc,
                style: AppTypography.body.copyWith(
                  color: tokens.text,
                ),
                decoration: InputDecoration(
                  labelText: 'Açıklama (opsiyonel)',
                  labelStyle: AppTypography.body.copyWith(
                    color: tokens.muted,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                style: AppTypography.body.copyWith(
                  color: tokens.text,
                ),
                decoration: InputDecoration(
                  labelText: 'Fiyat',
                  hintText: '0,00',
                  labelStyle: AppTypography.body.copyWith(
                    color: tokens.muted,
                  ),
                  hintStyle: AppTypography.body.copyWith(
                    color: tokens.muted,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // INGREDIENTS
              _sectionHeader(
                context,
                title: 'İçerikler',
                subtitle: 'Ürünün içeriğini buradan yönet.',
                icon: Icons.format_list_bulleted,
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _ingSearch,
                style: AppTypography.body.copyWith(
                  color: tokens.text,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Örn: sucuk, yumurta, kaşar',
                  hintStyle: AppTypography.body.copyWith(
                    color: tokens.muted,
                  ),
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
                          title: Text(
                            it.name,
                            style: AppTypography.bodyStrong.copyWith(
                              color: tokens.text,
                            ),
                          ),
                          subtitle: Text(
                            '${it.unit.label}${(it.note ?? '').trim().isEmpty ? '' : ' · ${it.note}'}',
                            style: AppTypography.caption.copyWith(
                              color: tokens.muted,
                            ),
                          ),
                          onTap: () => _addIngredientFlow(existingItem: it),
                        ),
                      ),
                      if (_suggestions.isEmpty || !_hasExactName)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.add),
                          title: Text(
                            '"$_q" ekle',
                            style: AppTypography.bodyStrong.copyWith(
                              color: tokens.text,
                            ),
                          ),
                          subtitle: Text(
                            'Birim seçerek oluştur',
                            style: AppTypography.caption.copyWith(
                              color: tokens.muted,
                            ),
                          ),
                          onTap: _addNewIngredientFromQuery,
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              if (_p.ingredients.isEmpty)
                _emptyHint(context, text: 'Bu üründe içerik yok.')
              else
                ..._p.ingredients.map((ref) {
                  final it = _libById[ref.ingredientId];
                  final name = it?.name ?? 'Bilinmeyen içerik';
                  final unit =
                  (ref.unitOverride ?? it?.unit ?? IngredientUnit.adet);

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
                                      style: AppTypography.bodyStrong.copyWith(
                                        color: tokens.text,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Birim: ${unit.label}',
                                      style: AppTypography.caption.copyWith(
                                        color: tokens.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeRef(ref),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: t.colorScheme.error,
                                ),
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
                                  onChanged: (v) => _setUnitOverride(ref, v),
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
                                  style: AppTypography.body.copyWith(
                                    color: tokens.text,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Miktar',
                                    labelStyle: AppTypography.body.copyWith(
                                      color: tokens.muted,
                                    ),
                                    suffixText: unit.label,
                                    suffixStyle: AppTypography.bodyStrong
                                        .copyWith(
                                      color: tokens.muted,
                                    ),
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

              const SizedBox(height: 18),

              // CUSTOMER CHOICES
              _sectionHeader(
                context,
                title: 'Müşteri Seçimleri',
                subtitle:
                'Pişirme derecesi, içecek boyu, ekstra sos gibi seçenek grupları.',
                icon: Icons.tune,
                trailing: FilledButton.icon(
                  onPressed: _addOptionGroup,
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Grup Ekle',
                    style: AppTypography.button.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              if (_p.optionGroups.isEmpty)
                _emptyHint(
                  context,
                  text: 'Seçenek grubu yok. “Grup Ekle” ile başlayabilirsin.',
                )
              else
                ..._p.optionGroups.map((g) => _optionGroupCard(context, g)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionGroupCard(BuildContext context, ProductOptionGroup g) {
    final t = Theme.of(context);
    final tokens = Theme.of(context).extension<AppTokens>()!;

    final rule = '${g.selectType.label} • min ${g.minSelect} / max ${g.maxSelect}';
    final preview = g.options.isEmpty
        ? 'Seçenek yok'
        : g.options.take(3).map((o) {
      final d = o.priceDelta;
      if (d == 0) return o.name;
      final s = d.toStringAsFixed(2).replaceAll('.', ',');
      return '${o.name} (+$s ₺)';
    }).join(' · ');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g.title,
                    style: AppTypography.bodyStrong.copyWith(
                      color: tokens.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rule,
                    style: AppTypography.caption.copyWith(
                      color: tokens.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: tokens.text,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Düzenle',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editOptionGroup(g),
            ),
            IconButton(
              tooltip: 'Sil',
              icon: Icon(
                Icons.delete_outline,
                color: t.colorScheme.error,
              ),
              onPressed: () => _removeOptionGroup(g.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addOptionGroup() async {
    final created = await _openOptionGroupEditor(
      initial: ProductOptionGroup(
        id: _uuid.v4(),
        title: '',
        selectType: OptionSelectType.single,
        minSelect: 0,
        maxSelect: 1,
        options: const [],
      ),
      sheetTitle: 'Seçenek Grubu Ekle',
    );

    if (created == null) return;

    setState(() {
      _p = _p.copyWith(optionGroups: [..._p.optionGroups, created]);
    });
  }

  Future<void> _editOptionGroup(ProductOptionGroup g) async {
    final updated = await _openOptionGroupEditor(
      initial: g,
      sheetTitle: 'Seçenek Grubu Düzenle',
    );

    if (updated == null) return;

    setState(() {
      _p = _p.copyWith(
        optionGroups: _p.optionGroups
            .map((x) => x.id == g.id ? updated : x)
            .toList(),
      );
    });
  }

  void _removeOptionGroup(String groupId) {
    setState(() {
      _p = _p.copyWith(
        optionGroups:
        _p.optionGroups.where((x) => x.id != groupId).toList(),
      );
    });
  }

  Future<ProductOptionGroup?> _openOptionGroupEditor({
    required ProductOptionGroup initial,
    required String sheetTitle,
  }) async {
    final titleC = TextEditingController(text: initial.title);

    OptionSelectType type = initial.selectType;
    int minSel = initial.minSelect;
    int maxSel = initial.maxSelect;
    List<ProductOptionItem> options = [...initial.options];

    return showModalBottomSheet<ProductOptionGroup>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final tokens = Theme.of(ctx).extension<AppTokens>()!;

        return StatefulBuilder(
          builder: (ctx, setSheet) {
            void clampRules() {
              if (maxSel < 1) maxSel = 1;
              if (minSel < 0) minSel = 0;
              if (minSel > maxSel) minSel = maxSel;
              if (type == OptionSelectType.single) {
                if (maxSel > 1) maxSel = 1;
                if (minSel > 1) minSel = 1;
              }
            }

            clampRules();

            String rulesHint() {
              if (type == OptionSelectType.single) {
                return 'Tek seçim: max 1 önerilir (min 0 veya 1)';
              }
              return 'Çoklu seçim: max >= 1 olmalı';
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 10,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sheetTitle,
                            style: AppTypography.title.copyWith(
                              color: tokens.text,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Kapat',
                            style: AppTypography.bodyStrong.copyWith(
                              color: tokens.muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            final title = titleC.text.trim();
                            if (title.isEmpty) return;

                            clampRules();

                            final fixed = ProductOptionGroup(
                              id: initial.id,
                              title: title,
                              selectType: type,
                              minSelect: minSel,
                              maxSelect: maxSel,
                              options: options,
                            );
                            Navigator.pop(ctx, fixed);
                          },
                          child: Text(
                            'Kaydet',
                            style: AppTypography.button.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleC,
                      style: AppTypography.body.copyWith(
                        color: tokens.text,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Grup adı',
                        hintText: 'Örn: Pişirme Derecesi',
                        labelStyle: AppTypography.body.copyWith(
                          color: tokens.muted,
                        ),
                        hintStyle: AppTypography.body.copyWith(
                          color: tokens.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<OptionSelectType>(
                      initialValue: type,
                      decoration: InputDecoration(
                        labelText: 'Seçim tipi',
                        labelStyle: AppTypography.body.copyWith(
                          color: tokens.muted,
                        ),
                      ),
                      items: OptionSelectType.values
                          .map(
                            (v) => DropdownMenuItem(
                          value: v,
                          child: Text(
                            v.label,
                            style: AppTypography.body.copyWith(
                              color: tokens.text,
                            ),
                          ),
                        ),
                      )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setSheet(() {
                          type = v;
                          if (type == OptionSelectType.single) {
                            maxSel = 1;
                            if (minSel > 1) minSel = 1;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: minSel.toString(),
                            keyboardType: TextInputType.number,
                            style: AppTypography.body.copyWith(
                              color: tokens.text,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Min seçim',
                              labelStyle: AppTypography.body.copyWith(
                                color: tokens.muted,
                              ),
                            ),
                            onChanged: (v) => setSheet(() {
                              minSel = int.tryParse(v.trim()) ?? minSel;
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            initialValue: maxSel.toString(),
                            keyboardType: TextInputType.number,
                            style: AppTypography.body.copyWith(
                              color: tokens.text,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Max seçim',
                              labelStyle: AppTypography.body.copyWith(
                                color: tokens.muted,
                              ),
                            ),
                            onChanged: (v) => setSheet(() {
                              maxSel = int.tryParse(v.trim()) ?? maxSel;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        rulesHint(),
                        style: AppTypography.caption.copyWith(
                          color: tokens.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Seçenekler',
                            style: AppTypography.bodyStrong.copyWith(
                              color: tokens.text,
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () async {
                            final created = await _openOptionItemEditor(
                              title: 'Seçenek Ekle',
                              initial: ProductOptionItem(
                                id: _uuid.v4(),
                                name: '',
                                priceDelta: 0,
                              ),
                            );
                            if (created == null) return;
                            setSheet(() => options = [...options, created]);
                          },
                          icon: const Icon(Icons.add),
                          label: Text(
                            'Ekle',
                            style: AppTypography.button.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (options.isEmpty)
                      _emptyHint(ctx, text: 'Henüz seçenek yok.')
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (_, i) {
                            final o = options[i];
                            final d = o.priceDelta;
                            final priceText = d == 0
                                ? 'Ücretsiz'
                                : '+${d.toStringAsFixed(2).replaceAll(".", ",")} ₺';

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  o.name.isEmpty
                                      ? 'İsimsiz seçenek'
                                      : o.name,
                                  style: AppTypography.bodyStrong.copyWith(
                                    color: tokens.text,
                                  ),
                                ),
                                subtitle: Text(
                                  priceText,
                                  style: AppTypography.caption.copyWith(
                                    color: tokens.muted,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Düzenle',
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () async {
                                        final updated =
                                        await _openOptionItemEditor(
                                          title: 'Seçeneği Düzenle',
                                          initial: o,
                                        );
                                        if (updated == null) return;
                                        setSheet(() {
                                          options = options
                                              .map((x) => x.id == o.id ? updated : x)
                                              .toList();
                                        });
                                      },
                                    ),
                                    IconButton(
                                      tooltip: 'Sil',
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Theme.of(ctx).colorScheme.error,
                                      ),
                                      onPressed: () {
                                        setSheet(() {
                                          options = options
                                              .where((x) => x.id != o.id)
                                              .toList();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<ProductOptionItem?> _openOptionItemEditor({
    required String title,
    required ProductOptionItem initial,
  }) async {
    final nameC = TextEditingController(text: initial.name);
    final priceC = TextEditingController(
      text: initial.priceDelta.toStringAsFixed(2).replaceAll('.', ','),
    );

    return showDialog<ProductOptionItem>(
      context: context,
      builder: (ctx) {
        final tokens = Theme.of(ctx).extension<AppTokens>()!;

        return AlertDialog(
          title: Text(
            title,
            style: AppTypography.title.copyWith(
              color: tokens.text,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                style: AppTypography.body.copyWith(
                  color: tokens.text,
                ),
                decoration: InputDecoration(
                  labelText: 'Seçenek adı',
                  hintText: 'Örn: Orta',
                  labelStyle: AppTypography.body.copyWith(
                    color: tokens.muted,
                  ),
                  hintStyle: AppTypography.body.copyWith(
                    color: tokens.muted,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceC,
                keyboardType: TextInputType.number,
                style: AppTypography.body.copyWith(
                  color: tokens.text,
                ),
                decoration: InputDecoration(
                  labelText: 'Fiyat farkı',
                  hintText: '0,00',
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
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'İptal',
                style: AppTypography.bodyStrong.copyWith(
                  color: tokens.muted,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                final n = nameC.text.trim();
                if (n.isEmpty) return;

                final d = double.tryParse(priceC.text.replaceAll(',', '.')) ?? 0;

                Navigator.pop(
                  ctx,
                  ProductOptionItem(
                    id: initial.id,
                    name: n,
                    priceDelta: d,
                  ),
                );
              },
              child: Text(
                'Kaydet',
                style: AppTypography.button.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _commit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;

    final price = double.tryParse(_price.text.replaceAll(',', '.')) ?? 0;

    final updated = _p.copyWith(
      name: name,
      description: _desc.text.trim(),
      price: price,
    );

    Navigator.pop(
      context,
      ProductEditResult(
        product: updated,
        updatedLibrary: _lib,
      ),
    );
  }

  Future<void> _addIngredientFlow({
    required IngredientLibraryItem existingItem,
  }) async {
    if (_p.ingredients.any((x) => x.ingredientId == existingItem.id)) {
      _ingSearch.clear();
      return;
    }

    final picked = await showDialog<pick_dialog.IngredientPickResult>(
      context: context,
      builder: (_) => pick_dialog.IngredientPickDialog(
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
      builder: (_) => quick_dialog.IngredientQuickCreateDialog(
        initialName: rawName,
        newId: _uuid.v4(),
      ),
    );

    if (created == null) return;

    setState(() => _lib = [..._lib, created]);

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
            .map(
              (x) => x.ingredientId == ref.ingredientId
              ? x.copyWith(amount: amount)
              : x,
        )
            .toList(),
      );
    });
  }

  void _setUnitOverride(ProductIngredientRef ref, IngredientUnit unit) {
    setState(() {
      _p = _p.copyWith(
        ingredients: _p.ingredients
            .map(
              (x) => x.ingredientId == ref.ingredientId
              ? x.copyWith(unitOverride: unit, setUnitOverride: true)
              : x,
        )
            .toList(),
      );
    });
  }

  Widget _sectionHeader(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        Widget? trailing,
      }) {
    final t = Theme.of(context);
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: t.colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(tokens.rMd),
          ),
          child: Icon(icon, color: t.colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyStrong.copyWith(
                  color: tokens.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: tokens.muted,
                ),
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

  Widget _emptyHint(
      BuildContext context, {
        required String text,
      }) {
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

class ProductEditResult {
  final ProductModel product;
  final List<IngredientLibraryItem> updatedLibrary;

  const ProductEditResult({
    required this.product,
    required this.updatedLibrary,
  });
}

class IngredientUnitOverrideField extends FormField<IngredientUnit> {
  IngredientUnitOverrideField({
    super.key,
    required String label,
    required IngredientUnit initial,
    required ValueChanged<IngredientUnit> onChanged,
  }) : super(
    initialValue: initial,
    builder: (state) {
      return DropdownButtonFormField<IngredientUnit>(
        initialValue: state.value,
        decoration: InputDecoration(
          labelText: label,
          errorText: state.errorText,
        ),
        items: IngredientUnit.values
            .map(
              (u) => DropdownMenuItem(
            value: u,
            child: Text(u.label),
          ),
        )
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          state.didChange(v);
          onChanged(v);
        },
      );
    },
  );
}