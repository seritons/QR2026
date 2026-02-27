// lib/features/panel/menu/menu_viewmodel.dart
//
// ✅ Yeni VM: “anında yaz” (immediate persist) mimarisi
// - Menü/Category/Product/Ingredient/Extras/Combo/Event: create/edit/delete -> RPC ile anında yazar
// - Artık “Kaydet / İptal” yok (istersen UI’da gösterebilirsin ama noop)
// - Dirty/hash/snapshot kaldırıldı (çünkü state server ile hemen senkron)
//
// Notlar:
// - Client UUID kullanıyoruz (tmp id yok). Bu yüzden id_map artık fiilen gereksiz.
// - Ürün içerikleri (ingredients) ayrı RPC ile replace ediliyor: setProductIngredients
// - Ekstralar (extras) için DB tarafında ara tablo (product_extras) yazılacak demiştin.
//   Bu VM, extras değişince de “ürünü upsert” ediyor. Eğer backend extras’ı ayrı RPC ile yazıyorsa,
//   MenuService’te rpcSetProductExtras gibi bir fonksiyon ekleyip burada çağır.
//
// ÖNEMLİ: Bu dosya MenuService’te verdiğim yeni RPC wrapper’larına göre yazıldı.
// - upsertMenu / deleteMenu
// - upsertCategory / deleteCategory
// - upsertProduct / deleteProduct
// - upsertIngredientLibraryItem / deleteIngredientLibraryItem
// - setProductIngredients
// - upsertCombo / deleteCombo
// - upsertEvent / deleteEvent

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../app/sessions/menu_session.dart';
import '../../../services/menu_service.dart';
import 'menu_models.dart';

class MenuViewModel extends ChangeNotifier {
  final MenuService _menuService;
  final MenuSession _menuSession;

  final String businessId;

  MenuViewModel({
    required MenuService menuService,
    required MenuSession menuSession,
    required this.businessId,
  })  : _menuService = menuService,
        _menuSession = menuSession;

  void _log(String msg) => debugPrint('[MenuVM] $msg');

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<MenuModel> get menusLight => _menuSession.menusLight;
  MenuModel? get activeMenuFull => _menuSession.activeMenuFull;
  String? get activeMenuId => _menuSession.activeMenuId;

  bool get hasActiveMenu => _menuSession.activeMenuFull != null;

  final _uuid = const Uuid();

  // =========================================================
  // INIT
  // =========================================================
  Future<void> init({String? preferMenuId}) async {
    _setLoading(true);
    _setError(null);

    try {
      _log('init START businessId="$businessId" preferMenuId="$preferMenuId"');

      final light = await _menuService.fetchMenusLight(businessId: businessId);
      _menuSession.setMenusLight(light);

      final pickedId = (preferMenuId?.trim().isNotEmpty == true)
          ? preferMenuId!.trim()
          : (light.isNotEmpty ? light.first.id : null);

      if (pickedId == null) {
        _menuSession.clear();
        _log('init DONE (no menu on server)');
        return;
      }

      final full = await _menuService.fetchMenuFull(
        businessId: businessId,
        menuId: pickedId,
      );

      final normalized = _hydrateUiCaches(full);
      _menuSession.setActiveMenuFull(menuId: pickedId, menu: normalized);

      _log('init DONE activeMenuId="$pickedId"');
    } catch (e) {
      _setError(e.toString());
      _log('init ERROR=$e');
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // MENU SWITCH
  // =========================================================
  Future<void> selectMenu(String menuId) async {
    final mId = menuId.trim();
    if (mId.isEmpty) return;

    _setLoading(true);
    _setError(null);

    try {
      _log('selectMenu START menuId="$mId"');

      final full = await _menuService.fetchMenuFull(
        businessId: businessId,
        menuId: mId,
      );

      final normalized = _hydrateUiCaches(full);
      _menuSession.setActiveMenuFull(menuId: mId, menu: normalized);

      _log('selectMenu DONE');
    } catch (e) {
      _setError(e.toString());
      _log('selectMenu ERROR=$e');
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // MENU CREATE / UPDATE / DELETE (ANINDA)
  // =========================================================
  Future<void> createMenuAndSelect(String name) async {
    final n = name.trim();
    if (n.isEmpty) return;

    _setLoading(true);
    _setError(null);

    try {
      final id = _uuid.v4();

      final draft = MenuModel(
        id: id,
        businessId: businessId,
        name: n,
        categories: const [],
        ingredientLibrary: const [],
        combos: const [],
        events: const [],
      );

      _log('createMenuAndSelect START id=$id name="$n"');

      await _menuService.upsertMenu(businessId: businessId, menu: draft);

      // picker stabilize
      final light = await _menuService.fetchMenusLight(businessId: businessId);
      _menuSession.setMenusLight(light);

      // active set (local)
      _menuSession.setActiveMenuFull(menuId: draft.id, menu: draft);

      _log('createMenuAndSelect DONE');
    } catch (e) {
      _setError(e.toString());
      _log('createMenuAndSelect ERROR=$e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> renameActiveMenu(String newName) async {
    final menu = _menuSession.activeMenuFull;
    if (menu == null) return;

    final n = newName.trim();
    if (n.isEmpty) return;

    _setLoading(true);
    _setError(null);

    try {
      final updated = menu.copyWith(name: n);

      _log('renameActiveMenu START menuId=${menu.id} name="$n"');

      await _menuService.upsertMenu(businessId: businessId, menu: updated);

      // local update
      _menuSession.setActiveMenuFull(menuId: updated.id, menu: updated);

      // refresh picker names
      try {
        final light = await _menuService.fetchMenusLight(businessId: businessId);
        _menuSession.setMenusLight(light);
      } catch (_) {}

      _log('renameActiveMenu DONE');
    } catch (e) {
      _setError(e.toString());
      _log('renameActiveMenu ERROR=$e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteMenu(String menuId) async {
    final mId = menuId.trim();
    if (mId.isEmpty) return;

    _setLoading(true);
    _setError(null);

    try {
      _log('deleteMenu START menuId=$mId');

      await _menuService.deleteMenu(businessId: businessId, menuId: mId);

      final light = await _menuService.fetchMenusLight(businessId: businessId);
      _menuSession.setMenusLight(light);

      // Eğer aktif menüyü sildiysek, yeni bir aktif seç
      if (_menuSession.activeMenuId == mId) {
        final nextId = light.isNotEmpty ? light.first.id : null;
        if (nextId == null) {
          _menuSession.clear();
        } else {
          final full = await _menuService.fetchMenuFull(businessId: businessId, menuId: nextId);
          _menuSession.setActiveMenuFull(menuId: nextId, menu: _hydrateUiCaches(full));
        }
      }

      _log('deleteMenu DONE');
    } catch (e) {
      _setError(e.toString());
      _log('deleteMenu ERROR=$e');
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // CATEGORY: CREATE / UPDATE / DELETE (ANINDA)
  // =========================================================
  Future<void> createCategory(String name) async {
    final menu = _menuSession.activeMenuFull;
    if (menu == null) return;

    final n = name.trim();
    if (n.isEmpty) return;

    _setLoading(true);
    _setError(null);

    try {
      final cat = CategoryModel(
        id: _uuid.v4(),
        name: n,
        products: const [],
      );

      final sortOrder = menu.categories.length;

      _log('createCategory START menuId=${menu.id} catId=${cat.id}');

      await _menuService.upsertCategory(
        businessId: businessId,
        menuId: menu.id,
        category: cat,
        sortOrder: sortOrder,
      );

      final updated = menu.copyWith(categories: [...menu.categories, cat]);
      _menuSession.setActiveMenuFull(menuId: menu.id, menu: _hydrateUiCaches(updated));

      _log('createCategory DONE');
    } catch (e) {
      _setError(e.toString());
      _log('createCategory ERROR=$e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> renameCategory(CategoryModel cat, String newName) async {
    final menu = _menuSession.activeMenuFull;
    if (menu == null) return;

    final n = newName.trim();
    if (n.isEmpty) return;

    _setLoading(true);
    _setError(null);

    try {
      final updatedCat = cat.copyWith(name: n);

      _log('renameCategory START catId=${cat.id} name="$n"');

      await _menuService.upsertCategory(
        businessId: businessId,
        menuId: menu.id,
        category: updatedCat,
      );

      final updatedCats = menu.categories.map((c) => c.id == cat.id ? updatedCat : c).toList();
      final updatedMenu = menu.copyWith(categories: updatedCats);

      _menuSession.setActiveMenuFull(menuId: menu.id, menu: _hydrateUiCaches(updatedMenu));

      _log('renameCategory DONE');
    } catch (e) {
      _setError(e.toString());
      _log('renameCategory ERROR=$e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteCategory(CategoryModel cat) async {
    final menu = _menuSession.activeMenuFull;
    if (menu == null) return;

    _setLoading(true);
    _setError(null);

    try {
      _log('deleteCategory START catId=${cat.id}');

      await _menuService.deleteCategory(
        businessId: businessId,
        menuId: menu.id,
        categoryId: cat.id,
      );

      final updatedCats = menu.categories.where((c) => c.id != cat.id).toList();
      final updatedMenu = menu.copyWith(categories: updatedCats);

      _menuSession.setActiveMenuFull(menuId: menu.id, menu: _hydrateUiCaches(updatedMenu));

      _log('deleteCategory DONE');
    } catch (e) {
      _setError(e.toString());
      _log('deleteCategory ERROR=$e');
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // PRODUCT: CREATE / UPDATE / DELETE (ANINDA)
  // - Ürün kaydı: upsertProduct
  // - İçerikler: setProductIngredients (replace list)
  // =========================================================
  Future<void> createOrUpdateProduct({
    required CategoryModel category,
    required ProductModel product,
  }) async {
    final menu = _menuSession.activeMenuFull;
    if (menu == null) return;

    if (product.name.trim().isEmpty) {
      _setError('Ürün adı boş olamaz.');
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      _log('createOrUpdateProduct START productId=${product.id} catId=${category.id}');

      // 1) image upload varsa önce url üret
      final withImage = await _uploadPendingImageForOne(menu, productId: product.id);

      // product güncel halini menü içinden çek (image_url set olmuş olabilir)
      final freshProduct = _findProductInMenu(withImage, product.id) ?? product;

      // 2) product row upsert (extras dahil edebilirsin)
      await _menuService.upsertProduct(
        businessId: businessId,
        menuId: menu.id,
        categoryId: category.id,
        product: freshProduct,
      );

      // 3) ingredients replace
      await _menuService.setProductIngredients(
        businessId: businessId,
        menuId: menu.id,
        productId: freshProduct.id,
        ingredients: freshProduct.ingredients,
      );

      // 4) local state update (category içinde replace/append)
      final updatedMenu = _replaceOrAddProduct(menu: withImage, categoryId: category.id, product: freshProduct);
      _menuSession.setActiveMenuFull(menuId: menu.id, menu: _hydrateUiCaches(updatedMenu));

      _log('createOrUpdateProduct DONE');
    } catch (e) {
      _setError(e.toString());
      _log('createOrUpdateProduct ERROR=$e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteProduct({
    required String productId,
  }) async {
    final menu = _menuSession.activeMenuFull;
    if (menu == null) return;

    final pId = productId.trim();
    if (pId.isEmpty) return;

    _setLoading(true);
    _setError(null);

    try {
      _log('deleteProduct START productId=$pId');

      await _menuService.deleteProduct(
        businessId: businessId,
        menuId: menu.id,
        productId: pId,
      );

      final updatedCats = menu.categories.map((cat) {
        return cat.copyWith(products: cat.products.where((p) => p.id != pId).toList());
      }).toList();

      // ayrıca: başka ürünlerin extras listesinde bu productId varsa temizle
      final cleanedCats = updatedCats.map((cat) {
        final cleanedProds = cat.products.map((p) {
          final nextExtras = p.extras.where((x) => x.extraProductId != pId).toList();
          return p.copyWith(extras: nextExtras);
        }).toList();
        return cat.copyWith(products: cleanedProds);
      }).toList();

      final updatedMenu = menu.copyWith(categories: cleanedCats);
      _menuSession.setActiveMenuFull(menuId: menu.id, menu: _hydrateUiCaches(updatedMenu));

      _log('deleteProduct DONE');
    } catch (e) {
      _setError(e.toString());
      _log('deleteProduct ERROR=$e');
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // INGREDIENT LIBRARY: CREATE / UPDATE / DELETE (ANINDA)
  // =========================================================
  Future<IngredientLibraryItem?> createOrUpdateIngredientLibraryItem(IngredientLibraryItem item) async {
    final menu = _menuSession.activeMenuFull;
    if (menu == null) return null;

    if (item.name.trim().isEmpty) {
      _setError('İçerik adı boş olamaz.');
      return null;
    }

    _setLoading(true);
    _setError(null);

    try {
      _log('createOrUpdateIngredientLibraryItem START itemId=${item.id} name="${item.name}"');

      final resp = await _menuService.upsertIngredientLibraryItem(
        businessId: businessId,
        item: item,
      );

      // server item_id döndürüyorsa onu al (client uuid kullanıyorsan aynı olur)
      final serverId = (resp['item_id'] ?? item.id).toString();

      final normalized = item.id == serverId ? item : item.copyWith(id: serverId);

      final list = [...menu.ingredientLibrary];
      final idx = list.indexWhere((x) => x.id == item.id || x.id == serverId);
      if (idx >= 0) {
        list[idx] = normalized;
      } else {
        list.add(normalized);
      }

      final updatedMenu = menu.copyWith(ingredientLibrary: list);
      _menuSession.setActiveMenuFull(menuId: menu.id, menu: _hydrateUiCaches(updatedMenu));

      _log('createOrUpdateIngredientLibraryItem DONE');
      return normalized;
    } catch (e) {
      _setError(e.toString());
      _log('createOrUpdateIngredientLibraryItem ERROR=$e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteIngredientLibraryItem(String itemId) async {
    final menu = _menuSession.activeMenuFull;
    if (menu == null) return;

    final id = itemId.trim();
    if (id.isEmpty) return;

    _setLoading(true);
    _setError(null);

    try {
      _log('deleteIngredientLibraryItem START itemId=$id');

      await _menuService.deleteIngredientLibraryItem(
        businessId: businessId,
        itemId: id,
      );

      // local: library’den kaldır
      var updatedMenu = menu.copyWith(
        ingredientLibrary: menu.ingredientLibrary.where((x) => x.id != id).toList(),
      );

      // local: product_ingredients içinden de temizle (UI tutarlılık)
      final updatedCats = updatedMenu.categories.map((cat) {
        final updatedProds = cat.products.map((p) {
          final nextRefs = p.ingredients.where((r) => r.ingredientId != id).toList();
          return p.copyWith(ingredients: nextRefs);
        }).toList();
        return cat.copyWith(products: updatedProds);
      }).toList();

      updatedMenu = updatedMenu.copyWith(categories: updatedCats);

      _menuSession.setActiveMenuFull(menuId: menu.id, menu: _hydrateUiCaches(updatedMenu));

      _log('deleteIngredientLibraryItem DONE');
    } catch (e) {
      _setError(e.toString());
      _log('deleteIngredientLibraryItem ERROR=$e');
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // COMBO / EVENT: ANINDA SAVE / DELETE
  // =========================================================
  Future<void> saveCombo(ComboDraft combo) async {
    final menu = _menuSession.activeMenuFull;
    if (menu == null) return;

    _setLoading(true);
    _setError(null);

    try {
      _log('saveCombo START menuId=${menu.id} comboId=${combo.id}');

      await _menuService.upsertCombo(
        businessId: businessId,
        menuId: menu.id,
        combo: combo,
      );

      final list = [...menu.combos];
      final idx = list.indexWhere((x) => x.id == combo.id);
      if (idx >= 0) {
        list[idx] = combo;
      } else {
        list.add(combo);
      }

      _menuSession.setActiveMenuFull(menuId: menu.id, menu: menu.copyWith(combos: list));
      notifyListeners();

      _log('saveCombo DONE');
    } catch (e) {
      _setError(e.toString());
      _log('saveCombo ERROR=$e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteComboRemote(String comboId) async {
    final menu = _menuSession.activeMenuFull;
    if (menu == null) return;

    _setLoading(true);
    _setError(null);

    try {
      _log('deleteComboRemote START comboId=$comboId');

      await _menuService.deleteCombo(
        businessId: businessId,
        menuId: menu.id,
        comboId: comboId,
      );

      final updated = menu.copyWith(combos: menu.combos.where((c) => c.id != comboId).toList());
      _menuSession.setActiveMenuFull(menuId: menu.id, menu: updated);
      notifyListeners();

      _log('deleteComboRemote DONE');
    } catch (e) {
      _setError(e.toString());
      _log('deleteComboRemote ERROR=$e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveEvent(EventDraft event) async {
    final menu = _menuSession.activeMenuFull;
    if (menu == null) return;

    _setLoading(true);
    _setError(null);

    try {
      _log('saveEvent START eventId=${event.id}');

      await _menuService.upsertEvent(
        businessId: businessId,
        menuId: menu.id,
        event: event,
      );

      final list = [...menu.events];
      final idx = list.indexWhere((x) => x.id == event.id);
      if (idx >= 0) {
        list[idx] = event;
      } else {
        list.add(event);
      }

      _menuSession.setActiveMenuFull(menuId: menu.id, menu: menu.copyWith(events: list));
      notifyListeners();

      _log('saveEvent DONE');
    } catch (e) {
      _setError(e.toString());
      _log('saveEvent ERROR=$e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteEventRemote(String eventId) async {
    final menu = _menuSession.activeMenuFull;
    if (menu == null) return;

    _setLoading(true);
    _setError(null);

    try {
      _log('deleteEventRemote START eventId=$eventId');

      await _menuService.deleteEvent(
        businessId: businessId,
        menuId: menu.id,
        eventId: eventId,
      );

      final updated = menu.copyWith(events: menu.events.where((e) => e.id != eventId).toList());
      _menuSession.setActiveMenuFull(menuId: menu.id, menu: updated);
      notifyListeners();

      _log('deleteEventRemote DONE');
    } catch (e) {
      _setError(e.toString());
      _log('deleteEventRemote ERROR=$e');
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // EXTRAS: Local + Remote (ANINDA)
  // =========================================================

  ProductModel? findProductById(String productId) {
    final menu = _menuSession.activeMenuFull;
    if (menu == null) return null;

    for (final c in menu.categories) {
      for (final p in c.products) {
        if (p.id == productId) return p;
      }
    }
    return null;
  }

  List<ProductModel> getResolvedExtras(String productId) {
    final p = findProductById(productId);
    if (p == null) return const [];
    final out = <ProductModel>[];
    for (final r in p.extras) {
      final resolved = r.extraProduct ?? findProductById(r.extraProductId);
      if (resolved != null) out.add(resolved);
    }
    return out;
  }

  Future<void> addExtraToProduct({
    required String productId,
    required String extraProductId,
    int maxQty = 1,
    int sort = 0,
  }) async {
    final menu = _menuSession.activeMenuFull;
    if (menu == null) return;

    if (productId == extraProductId) {
      _setError('Bir ürün kendisini ekstra olarak alamaz.');
      return;
    }

    // döngü guard (basit)
    final extraProd = findProductById(extraProductId);
    if (extraProd != null && extraProd.extras.any((x) => x.extraProductId == productId)) {
      _setError('Döngü oluşuyor: ekstra ürün, zaten seni ekstra olarak içeriyor.');
      return;
    }

    final target = findProductById(productId);
    if (target == null) return;

    final exists = target.extras.any((x) => x.extraProductId == extraProductId);
    if (exists) return;

    final ref = ProductExtraRef(
      extraProductId: extraProductId,
      maxQty: maxQty < 1 ? 1 : maxQty,
      sort: sort,
      extraProduct: extraProd,
    );

    final updatedProduct = target.copyWith(
      extras: [...target.extras, ref]..sort((a, b) => a.sort.compareTo(b.sort)),
    );

    // ✅ anında sunucuya yaz: product upsert (backend extras yazmayı desteklemeli)
    await _persistProductById(menu: menu, product: updatedProduct);
  }

  Future<void> removeExtraFromProduct({
    required String productId,
    required String extraProductId,
  }) async {
    final menu = _menuSession.activeMenuFull;
    if (menu == null) return;

    final target = findProductById(productId);
    if (target == null) return;

    final updatedProduct = target.copyWith(
      extras: target.extras.where((x) => x.extraProductId != extraProductId).toList(),
    );

    await _persistProductById(menu: menu, product: updatedProduct);
  }

  Future<void> updateExtraMaxQty({
    required String productId,
    required String extraProductId,
    required int maxQty,
  }) async {
    final menu = _menuSession.activeMenuFull;
    if (menu == null) return;

    final target = findProductById(productId);
    if (target == null) return;

    final safeQty = maxQty < 1 ? 1 : maxQty;

    final updatedProduct = target.copyWith(
      extras: target.extras.map((x) {
        if (x.extraProductId != extraProductId) return x;
        return x.copyWith(maxQty: safeQty);
      }).toList(),
    );

    await _persistProductById(menu: menu, product: updatedProduct);
  }

  Future<void> updateExtraSort({
    required String productId,
    required String extraProductId,
    required int sort,
  }) async {
    final menu = _menuSession.activeMenuFull;
    if (menu == null) return;

    final target = findProductById(productId);
    if (target == null) return;

    final updatedExtras = target.extras.map((x) {
      if (x.extraProductId != extraProductId) return x;
      return x.copyWith(sort: sort);
    }).toList()
      ..sort((a, b) => a.sort.compareTo(b.sort));

    final updatedProduct = target.copyWith(extras: updatedExtras);

    await _persistProductById(menu: menu, product: updatedProduct);
  }

  // =========================================================
  // INTERNAL: persist one product (find its category, upsert product + ingredients)
  // =========================================================
  Future<void> _persistProductById({
    required MenuModel menu,
    required ProductModel product,
  }) async {
    // category resolve
    CategoryModel? cat;
    for (final c in menu.categories) {
      if (c.products.any((p) => p.id == product.id)) {
        cat = c;
        break;
      }
    }
    if (cat == null) {
      _setError('Ürün kategorisi bulunamadı.');
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      _log('_persistProductById START productId=${product.id}');

      await _menuService.upsertProduct(
        businessId: businessId,
        menuId: menu.id,
        categoryId: cat.id,
        product: product,
      );

      await _menuService.setProductIngredients(
        businessId: businessId,
        menuId: menu.id,
        productId: product.id,
        ingredients: product.ingredients,
      );

      final updatedMenu = _replaceOrAddProduct(menu: menu, categoryId: cat.id, product: product);
      _menuSession.setActiveMenuFull(menuId: menu.id, menu: _hydrateUiCaches(updatedMenu));

      _log('_persistProductById DONE');
    } catch (e) {
      _setError(e.toString());
      _log('_persistProductById ERROR=$e');
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // UI CACHE hydrate
  // =========================================================
  MenuModel _hydrateUiCaches(MenuModel menu) {
    final libById = <String, IngredientLibraryItem>{
      for (final x in menu.ingredientLibrary) x.id: x,
    };

    final prodById = <String, ProductModel>{};
    for (final c in menu.categories) {
      for (final p in c.products) {
        prodById[p.id] = p;
      }
    }

    final hydratedCats = menu.categories.map((cat) {
      final hydratedProds = cat.products.map((p) {
        final ingRefs = p.ingredients.map((r) {
          final ing = libById[r.ingredientId];
          if (ing == null) return r;
          return r.copyWith(ingredient: ing, setIngredient: true);
        }).toList();

        final exRefs = p.extras.map((x) {
          final ep = prodById[x.extraProductId];
          if (ep == null) return x;
          return x.copyWith(extraProduct: ep, setExtraProduct: true);
        }).toList();

        return p.copyWith(ingredients: ingRefs, extras: exRefs);
      }).toList();

      return cat.copyWith(products: hydratedProds);
    }).toList();

    return menu.copyWith(categories: hydratedCats);
  }

  // =========================================================
  // IMAGE upload helpers
  // =========================================================
  Future<MenuModel> _uploadPendingImageForOne(MenuModel menu, {required String productId}) async {
    // Bu yardımcı sadece tek ürünün imagePath’i varsa upload eder.
    // (Ürün edit sheet içinde hızlı “kaydet” için ideal)
    final outCats = <CategoryModel>[];
    var changed = false;

    for (final cat in menu.categories) {
      final outProds = <ProductModel>[];
      for (final p in cat.products) {
        if (p.id == productId && p.imagePath != null && p.imagePath!.trim().isNotEmpty) {
          final url = await _menuService.uploadProductImage(
            businessId: businessId,
            menuId: menu.id,
            productId: p.id,
            localPath: p.imagePath!,
          );
          outProds.add(p.copyWith(imageUrl: url, setImageUrl: true));
          changed = true;
        } else {
          outProds.add(p);
        }
      }
      outCats.add(cat.copyWith(products: outProds));
    }

    return changed ? menu.copyWith(categories: outCats) : menu;
  }

  ProductModel? _findProductInMenu(MenuModel menu, String productId) {
    for (final c in menu.categories) {
      for (final p in c.products) {
        if (p.id == productId) return p;
      }
    }
    return null;
  }

  MenuModel _replaceOrAddProduct({
    required MenuModel menu,
    required String categoryId,
    required ProductModel product,
  }) {
    final updatedCats = menu.categories.map((cat) {
      if (cat.id != categoryId) return cat;

      final list = [...cat.products];
      final idx = list.indexWhere((x) => x.id == product.id);
      if (idx >= 0) {
        list[idx] = product;
      } else {
        list.add(product);
      }
      return cat.copyWith(products: list);
    }).toList();

    return menu.copyWith(categories: updatedCats);
  }

  // =========================================================
  // Setters
  // =========================================================
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? v) {
    _error = v;
    notifyListeners();
  }
}