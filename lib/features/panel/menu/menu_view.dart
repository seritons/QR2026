import 'package:flutter/material.dart';

import 'package:qrpanel/features/panel/menu/widgets/ComboCreatorSheet.dart';
import 'package:qrpanel/features/panel/menu/widgets/ProductEditorSheet.dart';
import 'package:qrpanel/features/panel/menu/widgets/event_creator_sheet.dart';
import 'package:uuid/uuid.dart';

import 'menu_models.dart';
import 'menu_viewmodel.dart';

class MenuCreateView extends StatefulWidget {
  final MenuViewModel vm;

  const MenuCreateView({
    super.key,
    required this.vm,
  });

  @override
  State<MenuCreateView> createState() => _MenuCreateViewState();
}

class _MenuCreateViewState extends State<MenuCreateView> {
  MenuViewModel get vm => widget.vm;

  void toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return ListenableBuilder(
      listenable: vm,
      builder: (_, __) {
        final menu = vm.activeMenuFull;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: openMenuPicker,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        menu?.name ?? 'Menü',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.expand_more),
                  ],
                ),
              ),
              bottom: (menu == null)
                  ? null
                  : const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Ürünler'),
                  Tab(text: 'Paketler'),
                  Tab(text: 'Kampanyalar'),
                ],
              ),
              actions: [
                if (vm.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  const SizedBox(width: 12),
              ],
            ),
            body: SafeArea(
              child: menu == null
                  ? buildNoMenuState(t)
                  : TabBarView(
                children: [
                  buildProductsTab(context, menu),
                  buildCombosTab(context, menu),
                  buildEventsTab(context, menu),
                ],
              ),
            ),
            floatingActionButton: (menu == null)
                ? null
                : FloatingActionButton.extended(
              onPressed: () async => await openQuickCreateSheet(menu),
              icon: const Icon(Icons.add),
              label: const Text('Yeni'),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // QUICK CREATE SHEET (category / product / combo / event)
  // ============================================================

  Future<void> openQuickCreateSheet(MenuModel menu) async {
    final picked = await showModalBottomSheet<_CreateItemType>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Kategori'),
              onTap: () => Navigator.pop(context, _CreateItemType.category),
            ),
            ListTile(
              leading: const Icon(Icons.fastfood_outlined),
              title: const Text('Ürün'),
              onTap: () => Navigator.pop(context, _CreateItemType.product),
            ),
            ListTile(
              leading: const Icon(Icons.fastfood_outlined),
              title: const Text('Paket'),
              onTap: () => Navigator.pop(context, _CreateItemType.combo),
            ),
            ListTile(
              leading: const Icon(Icons.local_offer_outlined),
              title: const Text('Kampanya'),
              onTap: () => Navigator.pop(context, _CreateItemType.event),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (picked == null) return;

    switch (picked) {
      case _CreateItemType.category:
        final name = await textDialog('Kategori Ekle', hint: 'Örn: Kahveler');
        if (name == null || name.trim().isEmpty) return;
        await vm.createCategory(name.trim());
        if (!mounted) return;
        if (vm.error != null) toast(vm.error!);
        return;

      case _CreateItemType.product:
      // Ürün eklemek için kategori seçtir
        final cat = await pickCategory(menu);
        if (cat == null) return;
        await addOrEditProduct(menu, cat);
        return;

      case _CreateItemType.combo:
        final draft = await openComboCreator(menu);
        if (draft == null) return;
        await vm.saveCombo(draft);
        if (!mounted) return;
        if (vm.error == null) {
          toast('Paket kaydedildi.');
        } else {
          toast(vm.error!);
        }
        return;

      case _CreateItemType.event:
        final draft = await openEventCreator(menu);
        if (draft == null) return;
        await vm.saveEvent(draft);
        if (!mounted) return;
        if (vm.error == null) {
          toast('Kampanya kaydedildi.');
        } else {
          toast(vm.error!);
        }
        return;
    }
  }

  // ============================================================
  // NO MENU STATE
  // ============================================================

  Widget buildNoMenuState(ThemeData t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            elevation: 0,
            color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant_menu,
                      size: 40, color: t.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Menü yok',
                    style: t.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Önce bir menü oluştur.',
                    style: t.textTheme.bodyMedium?.copyWith(color: t.hintColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: createMenuFlow,
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni Menü'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TAB 1: PRODUCTS
  // ============================================================

  Widget buildProductsTab(BuildContext context, MenuModel menu) {
    final t = Theme.of(context);

    final libById = {for (final i in menu.ingredientLibrary) i.id: i};
    final allProducts = allProductsOf(menu);
    final prodById = {for (final p in allProducts) p.id: p};

    if (menu.categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 0,
              color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restaurant_menu,
                        size: 40, color: t.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Menü boş',
                      style: t.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Önce kategori ekle, sonra ürünlerini oluştur.',
                      style: t.textTheme.bodyMedium?.copyWith(color: t.hintColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () async {
                        final name = await textDialog('Kategori Ekle', hint: 'Örn: Kahveler');
                        if (name == null || name.trim().isEmpty) return;
                        await vm.createCategory(name.trim());
                        if (!mounted) return;
                        if (vm.error != null) toast(vm.error!);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Kategori Ekle'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (vm.error != null) ...[
          Card(
            elevation: 0,
            color: t.colorScheme.errorContainer.withValues(alpha: 0.55),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: t.colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vm.error!,
                      style: t.textTheme.bodyMedium?.copyWith(
                        color: t.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        ...menu.categories.map((cat) {
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cat.name,
                          style: t.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Yeniden adlandır',
                        onPressed: () async {
                          final name = await textDialog(
                            'Kategori Adı',
                            hint: 'Kategori',
                            initial: cat.name,
                          );
                          if (name == null || name.trim().isEmpty) return;
                          await vm.renameCategory(cat, name.trim());
                          if (!mounted) return;
                          if (vm.error != null) toast(vm.error!);
                        },
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Sil',
                        onPressed: () async {
                          final ok = await confirmDialog(
                            title: 'Kategoriyi sil?',
                            message: '"${cat.name}" ve içindeki ürünler silinecek.',
                            confirmText: 'Sil',
                          );
                          if (ok != true) return;
                          await vm.deleteCategory(cat);
                          if (!mounted) return;
                          if (vm.error != null) toast(vm.error!);
                        },
                        icon: Icon(Icons.delete_outline, color: t.colorScheme.error),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (cat.products.isEmpty)
                    Text(
                      'Bu kategoride ürün yok.',
                      style: t.textTheme.bodySmall?.copyWith(color: t.hintColor),
                    )
                  else
                    ...cat.products.map((p) {
                      final ingText = p.ingredients.take(2).map((ref) {
                        final it = libById[ref.ingredientId];
                        if (it == null) return null;
                        final unit = (ref.unitOverride ?? it.unit).label;
                        return '${it.name} (${ref.amount} $unit)';
                      }).whereType<String>().join(' · ');

                      final extraNames = p.extras
                          .map((x) => prodById[x.extraProductId]?.name)
                          .whereType<String>()
                          .toList();

                      final extraText = extraNames.isEmpty
                          ? null
                          : 'Ekstralar: ${extraNames.take(2).join(' · ')}'
                          '${extraNames.length > 2 ? ' +' : ''}';

                      final subtitleLines = <String>[];
                      if (ingText.isNotEmpty) subtitleLines.add(ingText);
                      if (extraText != null) subtitleLines.add(extraText);
                      if (subtitleLines.isEmpty) subtitleLines.add('İçerik/ekstra eklenmemiş');

                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          p.name,
                          style: t.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          subtitleLines.join('\n'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.textTheme.bodySmall?.copyWith(color: t.hintColor),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${p.price.toStringAsFixed(2).replaceAll(".", ",")} ₺',
                              style: t.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              tooltip: 'Ekstralar',
                              onPressed: () async {
                                final updatedExtras = await editProductExtras(menu, cat, p);
                                if (updatedExtras == null) return;

                                // ✅ anında yaz
                                final updatedProduct = p.copyWith(extras: updatedExtras);
                                await vm.createOrUpdateProduct(category: cat, product: updatedProduct);
                                if (!mounted) return;
                                if (vm.error != null) toast(vm.error!);
                              },
                              icon: const Icon(Icons.extension_outlined),
                            ),
                          ],
                        ),
                        onTap: () async {
                          await addOrEditProduct(menu, cat, existing: p);
                        },
                        onLongPress: () async {
                          final ok = await confirmDialog(
                            title: 'Ürünü sil?',
                            message: '"${p.name}" silinecek.',
                            confirmText: 'Sil',
                          );
                          if (ok != true) return;

                          await vm.deleteProduct(productId: p.id);
                          if (!mounted) return;
                          if (vm.error == null) toast('Ürün silindi.');
                          if (vm.error != null) toast(vm.error!);
                        },
                      );
                    }),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await addOrEditProduct(menu, cat);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Ürün Ekle'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ============================================================
  // EXTRA EDITOR (BottomSheet)
  // ============================================================

  Future<List<ProductExtraRef>?> editProductExtras(
      MenuModel menu,
      CategoryModel cat,
      ProductModel product,
      ) async {
    final all = allProductsOf(menu);
    final candidates = all.where((p) => p.id != product.id).toList();

    final selected = <String, ProductExtraRef>{
      for (final x in product.extras) x.extraProductId: x,
    };

    String query = '';

    Future<void> editMaxQty(BuildContext ctx, String extraProductId) async {
      final current = selected[extraProductId]?.maxQty ?? 1;
      final txt = await textDialog(
        'Max adet',
        hint: 'Örn: 1 / 2 / 3',
        initial: current.toString(),
      );
      if (txt == null) return;
      final v = int.tryParse(txt.trim());
      final safe = (v == null || v < 1) ? 1 : v;

      final old = selected[extraProductId];
      selected[extraProductId] = (old == null)
          ? ProductExtraRef(
        extraProductId: extraProductId,
        maxQty: safe,
        sort: 0,
        extraProduct: null,
      )
          : old.copyWith(maxQty: safe);
    }

    final updatedExtras = await showModalBottomSheet<List<ProductExtraRef>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final filtered = candidates.where((p) {
              if (query.trim().isEmpty) return true;
              return p.name.toLowerCase().contains(query.trim().toLowerCase());
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ekstra seç',
                            style: Theme.of(ctx)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, null),
                          child: const Text('Vazgeç'),
                        ),
                        FilledButton(
                          onPressed: () {
                            final out = selected.values.toList()
                              ..sort((a, b) => a.sort.compareTo(b.sort));
                            Navigator.pop(ctx, out);
                          },
                          child: const Text('Tamam'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Ürün ara (ekstra)',
                      ),
                      onChanged: (v) => setSheet(() => query = v),
                    ),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Sonuç yok.',
                          style: Theme.of(ctx)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Theme.of(ctx).hintColor),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final p = filtered[i];
                            final isOn = selected.containsKey(p.id);
                            final maxQty = selected[p.id]?.maxQty ?? 1;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Checkbox(
                                value: isOn,
                                onChanged: (v) async {
                                  setSheet(() {
                                    if (v == true) {
                                      selected[p.id] = ProductExtraRef(
                                        extraProductId: p.id,
                                        maxQty: 1,
                                        sort: 0,
                                        extraProduct: p,
                                      );
                                    } else {
                                      selected.remove(p.id);
                                    }
                                  });
                                },
                              ),
                              title: Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${p.price.toStringAsFixed(2).replaceAll(".", ",")} ₺'
                                    '${isOn ? ' • max: $maxQty' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: isOn
                                  ? IconButton(
                                tooltip: 'Max adet',
                                icon: const Icon(Icons.tune),
                                onPressed: () async {
                                  await editMaxQty(ctx, p.id);
                                  setSheet(() {});
                                },
                              )
                                  : null,
                              onTap: () {
                                setSheet(() {
                                  if (!isOn) {
                                    selected[p.id] = ProductExtraRef(
                                      extraProductId: p.id,
                                      maxQty: 1,
                                      sort: 0,
                                      extraProduct: p,
                                    );
                                  } else {
                                    selected.remove(p.id);
                                  }
                                });
                              },
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

    return updatedExtras;
  }

  // ============================================================
  // TAB 2: COMBOS
  // ============================================================

  Widget buildCombosTab(BuildContext context, MenuModel menu) {
    final t = Theme.of(context);
    final allProducts = allProductsOf(menu);
    final prodById = {for (final p in allProducts) p.id: p};

    if (menu.combos.isEmpty) {
      return emptyTab(
        icon: Icons.fastfood_outlined,
        title: 'Paket yok',
        subtitle: 'Ürünlerden paket oluştur.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ...menu.combos.map((c) {
          final items = c.items.map((it) {
            final p = prodById[it.productId];
            final name = p?.name ?? 'Ürün';
            return '$name x${it.qty.toStringAsFixed(0)}';
          }).join(' • ');

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                c.name,
                style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(items, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Text(
                '${c.finalPrice.toStringAsFixed(2).replaceAll(".", ",")} ₺',
                style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              onTap: () async {
                // düzenleme istersen burada ComboCreatorSheet’i initial ile açarsın
              },
              onLongPress: () async {
                final ok = await confirmDialog(
                  title: 'Paketi sil?',
                  message: '"${c.name}" silinecek.',
                  confirmText: 'Sil',
                );
                if (ok != true) return;

                await vm.deleteComboRemote(c.id);
                if (!mounted) return;
                if (vm.error == null) toast('Paket silindi.');
                if (vm.error != null) toast(vm.error!);
              },
            ),
          );
        }),
      ],
    );
  }

  // ============================================================
  // TAB 3: EVENTS
  // ============================================================

  Widget buildEventsTab(BuildContext context, MenuModel menu) {
    final t = Theme.of(context);

    if (menu.events.isEmpty) {
      return emptyTab(
        icon: Icons.local_offer_outlined,
        title: 'Kampanya yok',
        subtitle: 'Ürünlere indirim kampanyası oluştur.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ...menu.events.map((e) {
          final when = e.scheduleType.name; // oneTime / recurring
          final disc = '%${e.discountPercent.toStringAsFixed(0)}';

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                e.name,
                style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('$disc • $when • ${e.productIds.length} ürün'),
              trailing: Icon(Icons.chevron_right, color: t.hintColor),
              onLongPress: () async {
                final ok = await confirmDialog(
                  title: 'Kampanyayı sil?',
                  message: '"${e.name}" silinecek.',
                  confirmText: 'Sil',
                );
                if (ok != true) return;

                await vm.deleteEventRemote(e.id);
                if (!mounted) return;
                if (vm.error == null) toast('Kampanya silindi.');
                if (vm.error != null) toast(vm.error!);
              },
            ),
          );
        }),
      ],
    );
  }

  Widget emptyTab({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            elevation: 0,
            color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 40, color: t.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(title,
                      style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: t.textTheme.bodyMedium?.copyWith(color: t.hintColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MENU PICKER / CREATE MENU
  // ============================================================

  Future<void> openMenuPicker() async {
    final menus = vm.menusLight;
    final currentId = vm.activeMenuId;

    final selected = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(16, 80, 16, 0),
      items: [
        ...menus.map(
              (m) => PopupMenuItem(
            value: 'menu:${m.id}',
            child: Row(
              children: [
                if (m.id == currentId)
                  const Icon(Icons.check, size: 18)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(m.name, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'new',
          child: Row(
            children: [
              Icon(Icons.add, size: 18),
              SizedBox(width: 8),
              Text('Yeni Menü Oluştur'),
            ],
          ),
        ),
      ],
    );

    if (selected == null) return;

    if (selected == 'new') {
      await createMenuFlow();
      return;
    }

    if (selected.startsWith('menu:')) {
      final id = selected.substring('menu:'.length);
      await vm.selectMenu(id);
      if (mounted && vm.error != null) toast(vm.error!);
    }
  }

  Future<void> createMenuFlow() async {
    final name = await textDialog('Yeni Menü', hint: 'Örn: Kış Menüsü');
    if (name == null || name.trim().isEmpty) return;

    await vm.createMenuAndSelect(name.trim());

    if (!mounted) return;
    if (vm.error != null) toast(vm.error!);
  }

  // ============================================================
  // PRODUCT ops
  // ============================================================

  Future<void> addOrEditProduct(
      MenuModel menu,
      CategoryModel cat, {
        ProductModel? existing,
      }) async {
    final result = await showModalBottomSheet<ProductEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductEditorSheet(
        title: existing == null ? 'Ürün Ekle' : 'Ürün Düzenle',
        initial: existing ??
            ProductModel(
              id: const Uuid().v4(),
              name: '',
              description: '',
              price: 0,
              ingredients: const [],
              extras: const [],
            ),
        ingredientLibrary: menu.ingredientLibrary, allProducts: [],
      ),
    );

    if (result == null) return;

    final p = result.product;
    if (p.name.trim().isEmpty) {
      toast('Ürün adı boş olamaz.');
      return;
    }

    // önce ingredient library update (sheet yeni item eklemiş olabilir)
    // burada “toplu save” yok; tek tek kaydediyoruz.
    // sheet’in updatedLibrary listesindeki farkları sunucuya yazmak istersen:
    // - ProductEditorSheet içinde, ingredient create/edit anında vm.createOrUpdateIngredientLibraryItem çağırmak daha doğru.
    // Şimdilik local state'i VM zaten fetch ile toparlar.

    await vm.createOrUpdateProduct(category: cat, product: p);

    if (!mounted) return;
    if (vm.error == null) toast(existing == null ? 'Ürün eklendi.' : 'Ürün güncellendi.');
    if (vm.error != null) toast(vm.error!);
  }

  // ============================================================
  // Combo / Event creators
  // ============================================================

  Future<ComboDraft?> openComboCreator(MenuModel menu) {
    final products = allProductsOf(menu);
    return showModalBottomSheet<ComboDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ComboCreatorSheet(
        products: products, // ✅ senin dosyandaki required param bu
        title: 'Paket Oluştur',
      ),
    );
  }

  Future<EventDraft?> openEventCreator(MenuModel menu) {
    final products = allProductsOf(menu);
    return showModalBottomSheet<EventDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventCreatorSheet(
        products: products,
        title: 'Kampanya Oluştur',
      ),
    );
  }

  List<ProductModel> allProductsOf(MenuModel menu) {
    final out = <ProductModel>[];
    for (final c in menu.categories) {
      out.addAll(c.products);
    }
    return out;
  }

  Future<CategoryModel?> pickCategory(MenuModel menu) async {
    if (menu.categories.isEmpty) {
      toast('Önce kategori ekle.');
      return null;
    }

    final pickedId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            ...menu.categories.map(
                  (c) => ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(c.name),
                onTap: () => Navigator.pop(context, c.id),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (pickedId == null) return null;
    return menu.categories.firstWhere((c) => c.id == pickedId);
  }

  // ============================================================
  // Dialog helpers
  // ============================================================

  Future<String?> textDialog(
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
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<bool?> confirmDialog({
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}

enum _CreateItemType { category, product, combo, event }

// ============================================================
// Product Editor result (sheet)
// ============================================================

class ProductEditResult {
  final ProductModel product;
  final List<IngredientLibraryItem> updatedLibrary;
  const ProductEditResult({
    required this.product,
    required this.updatedLibrary,
  });
}

// ============================================================
// DropdownButtonFormField 'value' deprecations fix helper
// ============================================================

class IngredientUnitOverrideField extends FormField<IngredientUnit> {
  IngredientUnitOverrideField({
    super.key,
    required String label,
    required IngredientUnit initial,
    required ValueChanged<IngredientUnit> onChanged,
  }) : super(
    initialValue: initial,
    builder: (state) {
      return InputDecorator(
        decoration:
        InputDecoration(labelText: label, errorText: state.errorText),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<IngredientUnit>(
            isExpanded: true,
            value: state.value,
            items: IngredientUnit.values
                .map((u) => DropdownMenuItem(value: u, child: Text(u.label)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              state.didChange(v);
              onChanged(v);
            },
          ),
        ),
      );
    },
  );
}