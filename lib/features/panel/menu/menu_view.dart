import 'package:flutter/material.dart';
import 'package:qrpanel/app/theme/app_typography.dart';
import 'package:qrpanel/app/theme/tokens.dart';
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
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      vm.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return ListenableBuilder(
      listenable: vm,
      builder: (_, __) {
        final menu = vm.activeMenuFull;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: InkWell(
                borderRadius: BorderRadius.circular(tokens.rMd),
                onTap: openMenuPicker,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        menu?.name ?? 'Menü',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title.copyWith(
                          color: tokens.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.expand_more, color: tokens.text),
                  ],
                ),
              ),
              bottom: (menu == null)
                  ? null
                  : TabBar(
                isScrollable: true,
                labelStyle: AppTypography.bodyStrong,
                unselectedLabelStyle: AppTypography.body,
                tabs: const [
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
                  ? _NoMenuState(onCreate: createMenuFlow)
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
              label: Text(
                'Yeni',
                style: AppTypography.button.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildProductsTab(BuildContext context, MenuModel menu) {
    final t = Theme.of(context);
    final tokens = Theme.of(context).extension<AppTokens>()!;

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
                    Icon(Icons.category_outlined, size: 40, color: t.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Kategori yok',
                      style: AppTypography.title.copyWith(color: tokens.text),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Önce bir kategori oluştur.',
                      style: AppTypography.body.copyWith(color: tokens.muted),
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
                      label: Text(
                        'Kategori Ekle',
                        style: AppTypography.button.copyWith(color: Colors.white),
                      ),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  final name = await textDialog('Kategori Ekle', hint: 'Örn: Kahveler');
                  if (name == null || name.trim().isEmpty) return;
                  await vm.createCategory(name.trim());
                  if (!mounted) return;
                  if (vm.error != null) toast(vm.error!);
                },
                icon: const Icon(Icons.add),
                label: Text(
                  'Kategori Ekle',
                  style: AppTypography.button.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...menu.categories.map((cat) {
          final prodCount = cat.products.length;

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.name,
                              style: AppTypography.title.copyWith(
                                color: tokens.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$prodCount ürün',
                              style: AppTypography.caption.copyWith(
                                color: tokens.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Kategori adını değiştir',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () async {
                          final newName = await textDialog(
                            'Kategori Düzenle',
                            hint: 'Kategori adı',
                            initial: cat.name,
                          );
                          if (newName == null || newName.trim().isEmpty) return;
                          await vm.renameCategory(cat, newName.trim());
                          if (!mounted) return;
                          if (vm.error != null) toast(vm.error!);
                        },
                      ),
                      IconButton(
                        tooltip: 'Kategori sil',
                        icon: Icon(Icons.delete_outline, color: t.colorScheme.error),
                        onPressed: () async {
                          final ok = await confirmDialog(
                            title: 'Kategori Silinsin mi?',
                            message: '“${cat.name}” kategorisi ve içindeki ürünler silinir.',
                          );
                          if (!ok) return;
                          await vm.deleteCategory(cat);
                          if (!mounted) return;
                          if (vm.error != null) toast(vm.error!);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (cat.products.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(tokens.rMd),
                        border: Border.all(color: t.dividerColor.withValues(alpha: 0.55)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: tokens.muted, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bu kategoride ürün yok.',
                              style: AppTypography.caption.copyWith(
                                color: tokens.muted,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => addOrEditProduct(menu, cat),
                            icon: const Icon(Icons.add),
                            label: Text(
                              'Ürün Ekle',
                              style: AppTypography.button.copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    ...cat.products.map((p) {
                      final price = p.price.toStringAsFixed(2).replaceAll('.', ',');
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          p.name,
                          style: AppTypography.bodyStrong.copyWith(
                            color: tokens.text,
                          ),
                        ),
                        subtitle: Text(
                          '$price ₺',
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
                              onPressed: () => addOrEditProduct(menu, cat, existing: p),
                            ),
                            IconButton(
                              tooltip: 'Sil',
                              icon: Icon(Icons.delete_outline, color: t.colorScheme.error),
                              onPressed: () async {
                                final ok = await confirmDialog(
                                  title: 'Ürün Silinsin mi?',
                                  message: '“${p.name}” silinir.',
                                );
                                if (!ok) return;
                                await vm.deleteProduct(productId: p.id);
                                if (!mounted) return;
                                if (vm.error != null) toast(vm.error!);
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: () => addOrEditProduct(menu, cat),
                        icon: const Icon(Icons.add),
                        label: Text(
                          'Ürün Ekle',
                          style: AppTypography.button.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget buildCombosTab(BuildContext context, MenuModel menu) {
    final t = Theme.of(context);
    final tokens = Theme.of(context).extension<AppTokens>()!;

    if (menu.combos.isEmpty) {
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
                    Icon(Icons.fastfood_outlined, size: 40, color: t.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Paket yok',
                      style: AppTypography.title.copyWith(color: tokens.text),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Örn: “Kahve + Kruvasan” gibi paketler oluşturabilirsin.',
                      style: AppTypography.body.copyWith(color: tokens.muted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () async {
                        final draft = await openComboCreator(menu);
                        if (draft == null) return;
                        vm.saveCombo(draft);
                        if (!mounted) return;
                        toast(vm.error == null ? 'Paket kaydedildi.' : vm.error!);
                      },
                      icon: const Icon(Icons.add),
                      label: Text(
                        'Paket Oluştur',
                        style: AppTypography.button.copyWith(color: Colors.white),
                      ),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        FilledButton.icon(
          onPressed: () async {
            final draft = await openComboCreator(menu);
            if (draft == null) return;
            vm.saveCombo(draft);
            if (!mounted) return;
            toast(vm.error == null ? 'Paket kaydedildi.' : vm.error!);
          },
          icon: const Icon(Icons.add),
          label: Text(
            'Yeni Paket',
            style: AppTypography.button.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        ...menu.combos.map((c) {
          return Card(
            elevation: 0,
            child: ListTile(
              title: Text(
                c.name,
                style: AppTypography.bodyStrong.copyWith(
                  color: tokens.text,
                ),
              ),
              subtitle: Text(
                (c.note ?? '').isEmpty ? '—' : c.note!,
                style: AppTypography.caption.copyWith(
                  color: tokens.muted,
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete_outline, color: t.colorScheme.error),
                onPressed: () async {
                  final ok = await confirmDialog(
                    title: 'Paket Silinsin mi?',
                    message: '“${c.name}” silinir.',
                  );
                  if (!ok) return;
                  vm.deleteComboLocal(c.id);
                  if (!mounted) return;
                  if (vm.error != null) toast(vm.error!);
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget buildEventsTab(BuildContext context, MenuModel menu) {
    final t = Theme.of(context);
    final tokens = Theme.of(context).extension<AppTokens>()!;

    if (menu.events.isEmpty) {
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
                    Icon(Icons.local_offer_outlined, size: 40, color: t.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Kampanya yok',
                      style: AppTypography.title.copyWith(color: tokens.text),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Örn: “Hafta içi 10:00-12:00 %15 indirim”.',
                      style: AppTypography.body.copyWith(color: tokens.muted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () async {
                        final draft = await openEventCreator(menu);
                        if (draft == null) return;
                        vm.saveEvent(draft);
                        if (!mounted) return;
                        toast(vm.error == null ? 'Kampanya kaydedildi.' : vm.error!);
                      },
                      icon: const Icon(Icons.add),
                      label: Text(
                        'Kampanya Oluştur',
                        style: AppTypography.button.copyWith(color: Colors.white),
                      ),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        FilledButton.icon(
          onPressed: () async {
            final draft = await openEventCreator(menu);
            if (draft == null) return;
            vm.saveEvent(draft);
            if (!mounted) return;
            toast(vm.error == null ? 'Kampanya kaydedildi.' : vm.error!);
          },
          icon: const Icon(Icons.add),
          label: Text(
            'Yeni Kampanya',
            style: AppTypography.button.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        ...menu.events.map((e) {
          return Card(
            elevation: 0,
            child: ListTile(
              title: Text(
                e.name,
                style: AppTypography.bodyStrong.copyWith(
                  color: tokens.text,
                ),
              ),
              subtitle: Text(
                '%${e.discountPercent.toStringAsFixed(0)} indirim',
                style: AppTypography.caption.copyWith(
                  color: tokens.muted,
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete_outline, color: t.colorScheme.error),
                onPressed: () async {
                  final ok = await confirmDialog(
                    title: 'Kampanya Silinsin mi?',
                    message: '“${e.name}” silinir.',
                  );
                  if (!ok) return;
                  vm.deleteEventLocal(e.id);
                  if (!mounted) return;
                  if (vm.error != null) toast(vm.error!);
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<bool> confirmDialog({
    required String title,
    required String message,
  }) async {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: AppTypography.title.copyWith(color: tokens.text),
        ),
        content: Text(
          message,
          style: AppTypography.body.copyWith(color: tokens.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Vazgeç',
              style: AppTypography.bodyStrong.copyWith(color: tokens.muted),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sil',
              style: AppTypography.button.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return res == true;
  }

  Future<void> openQuickCreateSheet(MenuModel menu) async {
    final tokens = Theme.of(context).extension<AppTokens>()!;

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
              title: Text(
                'Kategori',
                style: AppTypography.bodyStrong.copyWith(color: tokens.text),
              ),
              onTap: () => Navigator.pop(context, _CreateItemType.category),
            ),
            ListTile(
              leading: const Icon(Icons.fastfood_outlined),
              title: Text(
                'Ürün',
                style: AppTypography.bodyStrong.copyWith(color: tokens.text),
              ),
              onTap: () => Navigator.pop(context, _CreateItemType.product),
            ),
            ListTile(
              leading: const Icon(Icons.fastfood_outlined),
              title: Text(
                'Paket',
                style: AppTypography.bodyStrong.copyWith(color: tokens.text),
              ),
              onTap: () => Navigator.pop(context, _CreateItemType.combo),
            ),
            ListTile(
              leading: const Icon(Icons.local_offer_outlined),
              title: Text(
                'Kampanya',
                style: AppTypography.bodyStrong.copyWith(color: tokens.text),
              ),
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
        final cat = await pickCategory(menu);
        if (cat == null) return;
        await addOrEditProduct(menu, cat);
        return;

      case _CreateItemType.combo:
        final draft = await openComboCreator(menu);
        if (draft == null) return;
        vm.saveCombo(draft);
        if (!mounted) return;
        toast(vm.error == null ? 'Paket kaydedildi.' : vm.error!);
        return;

      case _CreateItemType.event:
        final draft = await openEventCreator(menu);
        if (draft == null) return;
        vm.saveEvent(draft);
        if (!mounted) return;
        toast(vm.error == null ? 'Kampanya kaydedildi.' : vm.error!);
        return;
    }
  }

  Future<void> openMenuPicker() async {
    final menus = vm.menusLight;
    final currentId = vm.activeMenuId;
    final tokens = Theme.of(context).extension<AppTokens>()!;

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
                Expanded(
                  child: Text(
                    m.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(color: tokens.text),
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'new',
          child: Row(
            children: [
              const Icon(Icons.add, size: 18),
              const SizedBox(width: 8),
              Text(
                'Yeni Menü Oluştur',
                style: AppTypography.bodyStrong.copyWith(color: tokens.text),
              ),
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
              optionGroups: const [],
            ),
        ingredientLibrary: menu.ingredientLibrary,
      ),
    );

    if (result == null) return;

    final p = result.product;
    if (p.name.trim().isEmpty) {
      toast('Ürün adı boş olamaz.');
      return;
    }

    await vm.createOrUpdateProduct(category: cat, product: p);

    if (!mounted) return;
    toast(
      vm.error == null
          ? (existing == null ? 'Ürün eklendi.' : 'Ürün güncellendi.')
          : vm.error!,
    );
  }

  Future<ComboDraft?> openComboCreator(MenuModel menu) {
    final products = _allProductsOf(menu);
    return showModalBottomSheet<ComboDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ComboCreatorSheet(products: products, title: 'Paket Oluştur'),
    );
  }

  Future<EventDraft?> openEventCreator(MenuModel menu) {
    final products = _allProductsOf(menu);
    return showModalBottomSheet<EventDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventCreatorSheet(products: products, title: 'Kampanya Oluştur'),
    );
  }

  List<ProductModel> _allProductsOf(MenuModel menu) {
    final out = <ProductModel>[];
    for (final c in menu.categories) {
      out.addAll(c.products);
    }
    return out;
  }

  Future<CategoryModel?> pickCategory(MenuModel menu) async {
    final tokens = Theme.of(context).extension<AppTokens>()!;

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
                title: Text(
                  c.name,
                  style: AppTypography.bodyStrong.copyWith(color: tokens.text),
                ),
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

  Future<String?> textDialog(
      String title, {
        required String hint,
        String initial = '',
      }) async {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: AppTypography.title.copyWith(color: tokens.text),
        ),
        content: TextField(
          controller: c,
          autofocus: true,
          style: AppTypography.body.copyWith(color: tokens.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.body.copyWith(color: tokens.muted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'İptal',
              style: AppTypography.bodyStrong.copyWith(color: tokens.muted),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text),
            child: Text(
              'Tamam',
              style: AppTypography.button.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

enum _CreateItemType { category, product, combo, event }

class _NoMenuState extends StatelessWidget {
  final VoidCallback onCreate;

  const _NoMenuState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tokens = Theme.of(context).extension<AppTokens>()!;

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
                  Icon(Icons.restaurant_menu, size: 40, color: t.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Menü yok',
                    style: AppTypography.title.copyWith(color: tokens.text),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Önce bir menü oluştur.',
                    style: AppTypography.body.copyWith(color: tokens.muted),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add),
                    label: Text(
                      'Yeni Menü',
                      style: AppTypography.button.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}