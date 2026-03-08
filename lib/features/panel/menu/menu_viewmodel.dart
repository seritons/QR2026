import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../app/sessions/menu_session.dart';
import '../../../services/menu_service.dart';
import 'menu_models.dart';

class MenuViewModel extends ChangeNotifier {
  final MenuSession session;
  final MenuService service;
  final String businessId;

  MenuViewModel({
    required this.session,
    required this.service,
    required this.businessId,
  });

  final _uuid = const Uuid();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _error;
  String? get error => _error;

  DateTime? _lastSyncAt;
  DateTime? get lastSyncAt => _lastSyncAt;

  List<MenuModel> get menusLight => session.menusLight;
  MenuModel? get activeMenuFull => session.activeMenuFull;
  String? get activeMenuId => session.activeMenuId;
  bool get hasActiveMenu => session.hasActiveMenu;

  // =========================================================
  // LOG HELPERS
  // =========================================================
  void _log(String msg) => debugPrint('[MenuVM] $msg');

  String _menuSummary(MenuModel? m) {
    if (m == null) return 'null';
    return 'Menu(id=${m.id}, name="${m.name}", '
        'cats=${m.categories.length}, '
        'lib=${m.ingredientLibrary.length}, '
        'combos=${m.combos.length}, '
        'events=${m.events.length})';
  }

  String _menusLightSummary(List<MenuModel> menus) {
    if (menus.isEmpty) return '[]';
    return menus.map((m) => '{id=${m.id}, name="${m.name}"}').join(', ');
  }

  void _logSessionState([String prefix = 'SESSION']) {
    _log(
      '$prefix '
          'activeMenuId=${session.activeMenuId} '
          'hasActiveMenu=${session.hasActiveMenu} '
          'menusLightCount=${session.menusLight.length} '
          'menusFullCount=${session.menusFull.length} '
          'activeMenu=${_menuSummary(session.activeMenuFull)}',
    );
  }

  void _logMethodStart(String name, [Map<String, Object?> extra = const {}]) {
    _log('--------------------------------------------------');
    _log('$name START');
    _log('$name state_before: '
        'isLoading=$_isLoading isSaving=$_isSaving error=$_error lastSyncAt=$_lastSyncAt');
    _log('$name businessId="$businessId"');
    if (extra.isNotEmpty) {
      _log('$name args=$extra');
    }
    _logSessionState('$name session_before');
  }

  void _logMethodDone(String name, [Map<String, Object?> extra = const {}]) {
    if (extra.isNotEmpty) {
      _log('$name result=$extra');
    }
    _logSessionState('$name session_after');
    _log('$name DONE');
    _log('--------------------------------------------------');
  }

  void _logMethodError(String name, Object e, [StackTrace? st]) {
    _log('$name ERROR=$e');
    if (st != null) {
      _log('$name STACK=$st');
    }
    _logSessionState('$name session_error');
    _log('--------------------------------------------------');
  }

  // =========================================================
  // INIT
  // =========================================================
  Future<void> init({String? preferMenuId}) async {
    _logMethodStart('init', {
      'preferMenuId': preferMenuId,
    });

    _setLoading(true);
    _setError(null);

    try {
      _log('init -> calling service.fetchMenusLight');
      final lightMenus = await service.fetchMenusLight(
        businessId: businessId,
      );

      _log('init <- service.fetchMenusLight returned count=${lightMenus.length}');
      _log('init lightMenus=${_menusLightSummary(lightMenus)}');

      session.setMenusLight(lightMenus, preferActiveMenuId: preferMenuId);
      _logSessionState('init after setMenusLight');

      final targetId = preferMenuId?.trim().isNotEmpty == true
          ? preferMenuId!.trim()
          : (lightMenus.isNotEmpty ? lightMenus.first.id : null);

      _log('init resolved targetId=$targetId');

      if (targetId != null) {
        _log('init -> calling service.fetchMenuFull(menuId="$targetId")');
        final full = await service.fetchMenuFull(
          businessId: businessId,
          menuId: targetId,
        );

        _log('init <- fetchMenuFull returned ${_menuSummary(full)}');
        session.upsertMenu(full, select: true);
        _logSessionState('init after upsertMenu(full)');
      } else {
        _log('init targetId is null, full menu fetch skipped');
      }

      _lastSyncAt = DateTime.now();

      _logMethodDone('init', {
        'lightMenusCount': lightMenus.length,
        'resolvedTargetId': targetId,
        'lastSyncAt': _lastSyncAt.toString(),
      });
    } catch (e, st) {
      _setError(e.toString());
      _logMethodError('init', e, st);
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // REFRESH
  // =========================================================
  Future<void> refreshActiveMenu() async {
    _logMethodStart('refreshActiveMenu');

    final menuId = session.activeMenuId;
    if (menuId == null || menuId.trim().isEmpty) {
      _log('refreshActiveMenu skipped: activeMenuId is null/empty');
      _logMethodDone('refreshActiveMenu', {
        'skipped': true,
        'reason': 'no_active_menu_id',
      });
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      _log('refreshActiveMenu -> fetchMenuFull(menuId="$menuId")');
      final full = await service.fetchMenuFull(
        businessId: businessId,
        menuId: menuId,
      );

      _log('refreshActiveMenu <- full=${_menuSummary(full)}');
      session.upsertMenu(full, select: true);
      _lastSyncAt = DateTime.now();

      _logMethodDone('refreshActiveMenu', {
        'menuId': menuId,
        'lastSyncAt': _lastSyncAt.toString(),
      });
    } catch (e, st) {
      _setError(e.toString());
      _logMethodError('refreshActiveMenu', e, st);
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // SELECT MENU
  // =========================================================
  Future<void> selectMenu(String menuId) async {
    _logMethodStart('selectMenu', {
      'menuId': menuId,
    });

    final id = menuId.trim();
    if (id.isEmpty) {
      _log('selectMenu skipped: menuId empty');
      _logMethodDone('selectMenu', {
        'skipped': true,
        'reason': 'empty_menu_id',
      });
      return;
    }

    _setError(null);
    _setLoading(true);

    try {
      final cached = session.findFullMenuById(id);
      _log('selectMenu cacheLookup menuId="$id" hit=${cached != null}');

      if (cached != null) {
        _log('selectMenu CACHE HIT -> session.selectActiveMenu("$id")');
        session.selectActiveMenu(id);
      } else {
        _log('selectMenu CACHE MISS -> fetchMenuFull("$id")');
        final full = await service.fetchMenuFull(
          businessId: businessId,
          menuId: id,
        );
        _log('selectMenu <- fetchMenuFull returned ${_menuSummary(full)}');
        session.upsertMenu(full, select: true);
      }

      _lastSyncAt = DateTime.now();

      _logMethodDone('selectMenu', {
        'selectedMenuId': id,
        'lastSyncAt': _lastSyncAt.toString(),
      });
    } catch (e, st) {
      _setError(e.toString());
      _logMethodError('selectMenu', e, st);
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // MENU CRUD
  // =========================================================
  Future<void> createMenuAndSelect(String name) async {
    _logMethodStart('createMenuAndSelect', {
      'name': name,
    });

    final n = name.trim();
    if (n.isEmpty) {
      _log('createMenuAndSelect skipped: empty name');
      _logMethodDone('createMenuAndSelect', {
        'skipped': true,
        'reason': 'empty_name',
      });
      return;
    }

    _setSaving(true);
    _setError(null);

    try {
      final draft = MenuModel(
        id: _uuid.v4(),
        businessId: businessId,
        name: n,
        categories: const [],
        ingredientLibrary: const [],
        combos: const [],
        events: const [],
      );

      _log('createMenuAndSelect draft=${_menuSummary(draft)}');

      _log('createMenuAndSelect -> service.upsertMenu');
      final upsertRes = await service.upsertMenu(
        businessId: businessId,
        menu: draft,
      );
      _log('createMenuAndSelect <- upsertMenu result=$upsertRes');

      final savedMenuId = (upsertRes['menu_id'] ?? draft.id).toString();
      _log('createMenuAndSelect resolved savedMenuId="$savedMenuId"');

      _log('createMenuAndSelect -> service.fetchMenuFull(savedMenuId)');
      final full = await service.fetchMenuFull(
        businessId: businessId,
        menuId: savedMenuId,
      );
      _log('createMenuAndSelect <- full=${_menuSummary(full)}');

      session.upsertMenu(full, select: true);
      _lastSyncAt = DateTime.now();

      _logMethodDone('createMenuAndSelect', {
        'savedMenuId': savedMenuId,
        'lastSyncAt': _lastSyncAt.toString(),
      });
    } catch (e, st) {
      _setError(e.toString());
      _logMethodError('createMenuAndSelect', e, st);
    } finally {
      _setSaving(false);
    }
  }

  Future<void> renameActiveMenu(String newName) async {
    _logMethodStart('renameActiveMenu', {
      'newName': newName,
    });

    final menu = session.activeMenuFull;
    if (menu == null) {
      _log('renameActiveMenu skipped: activeMenuFull is null');
      _logMethodDone('renameActiveMenu', {
        'skipped': true,
        'reason': 'no_active_menu',
      });
      return;
    }

    final n = newName.trim();
    if (n.isEmpty) {
      _log('renameActiveMenu skipped: newName empty');
      _logMethodDone('renameActiveMenu', {
        'skipped': true,
        'reason': 'empty_name',
      });
      return;
    }

    _setSaving(true);
    _setError(null);

    try {
      final updated = menu.copyWith(name: n);
      _log('renameActiveMenu updated=${_menuSummary(updated)}');

      final res = await service.upsertMenu(
        businessId: businessId,
        menu: updated,
      );
      _log('renameActiveMenu <- upsertMenu result=$res');

      session.updateActiveMenu(updated);
      _lastSyncAt = DateTime.now();

      _logMethodDone('renameActiveMenu', {
        'menuId': updated.id,
        'newName': n,
      });
    } catch (e, st) {
      _setError(e.toString());
      _logMethodError('renameActiveMenu', e, st);
    } finally {
      _setSaving(false);
    }
  }

  Future<void> deleteMenu(String menuId) async {
    _logMethodStart('deleteMenu', {
      'menuId': menuId,
    });

    final id = menuId.trim();
    if (id.isEmpty) {
      _log('deleteMenu skipped: empty menuId');
      _logMethodDone('deleteMenu', {
        'skipped': true,
        'reason': 'empty_menu_id',
      });
      return;
    }

    _setSaving(true);
    _setError(null);

    try {
      _log('deleteMenu -> service.deleteMenu("$id")');
      final res = await service.deleteMenu(
        businessId: businessId,
        menuId: id,
      );
      _log('deleteMenu <- result=$res');

      session.deleteMenu(id);
      _logSessionState('deleteMenu after session.deleteMenu');

      final nextId = session.activeMenuId;
      _log('deleteMenu nextActiveMenuId=$nextId');

      if (nextId != null && nextId.isNotEmpty) {
        _log('deleteMenu -> fetch next active full menu');
        final full = await service.fetchMenuFull(
          businessId: businessId,
          menuId: nextId,
        );
        _log('deleteMenu <- next full=${_menuSummary(full)}');
        session.upsertMenu(full, select: true);
      }

      _lastSyncAt = DateTime.now();

      _logMethodDone('deleteMenu', {
        'deletedMenuId': id,
        'nextActiveMenuId': nextId,
      });
    } catch (e, st) {
      _setError(e.toString());
      _logMethodError('deleteMenu', e, st);
    } finally {
      _setSaving(false);
    }
  }

  // =========================================================
  // CATEGORY CRUD
  // =========================================================
  Future<void> createCategory(String name) async {
    _logMethodStart('createCategory', {
      'name': name,
    });

    final menu = session.activeMenuFull;
    if (menu == null) {
      _log('createCategory skipped: activeMenuFull is null');
      _logMethodDone('createCategory', {
        'skipped': true,
        'reason': 'no_active_menu',
      });
      return;
    }

    final n = name.trim();
    if (n.isEmpty) {
      _log('createCategory skipped: empty name');
      _logMethodDone('createCategory', {
        'skipped': true,
        'reason': 'empty_name',
      });
      return;
    }

    _setSaving(true);
    _setError(null);

    try {
      final cat = CategoryModel(
        id: _uuid.v4(),
        name: n,
        products: const [],
      );

      _log('createCategory draftCategory id=${cat.id} name="${cat.name}" sortOrder=${menu.categories.length}');

      final res = await service.upsertCategory(
        businessId: businessId,
        menuId: menu.id,
        category: cat,
        sortOrder: menu.categories.length,
      );
      _log('createCategory <- result=$res');

      final updated = menu.copyWith(
        categories: [...menu.categories, cat],
      );
      session.updateActiveMenu(updated);
      _lastSyncAt = DateTime.now();

      _logMethodDone('createCategory', {
        'categoryId': cat.id,
        'menuId': menu.id,
      });
    } catch (e, st) {
      _setError(e.toString());
      _logMethodError('createCategory', e, st);
    } finally {
      _setSaving(false);
    }
  }

  Future<void> renameCategory(CategoryModel cat, String newName) async {
    _logMethodStart('renameCategory', {
      'categoryId': cat.id,
      'oldName': cat.name,
      'newName': newName,
    });

    final menu = session.activeMenuFull;
    if (menu == null) {
      _log('renameCategory skipped: no active menu');
      _logMethodDone('renameCategory', {
        'skipped': true,
        'reason': 'no_active_menu',
      });
      return;
    }

    final n = newName.trim();
    if (n.isEmpty) {
      _log('renameCategory skipped: empty newName');
      _logMethodDone('renameCategory', {
        'skipped': true,
        'reason': 'empty_name',
      });
      return;
    }

    _setSaving(true);
    _setError(null);

    try {
      final updatedCat = cat.copyWith(name: n);
      final sortOrder = menu.categories.indexWhere((c) => c.id == cat.id);

      _log('renameCategory resolved sortOrder=$sortOrder');

      final res = await service.upsertCategory(
        businessId: businessId,
        menuId: menu.id,
        category: updatedCat,
        sortOrder: sortOrder >= 0 ? sortOrder : null,
      );
      _log('renameCategory <- result=$res');

      final updatedCats = menu.categories
          .map((c) => c.id == cat.id ? updatedCat : c)
          .toList();

      session.updateActiveMenu(menu.copyWith(categories: updatedCats));
      _lastSyncAt = DateTime.now();

      _logMethodDone('renameCategory', {
        'categoryId': cat.id,
        'newName': n,
      });
    } catch (e, st) {
      _setError(e.toString());
      _logMethodError('renameCategory', e, st);
    } finally {
      _setSaving(false);
    }
  }

  Future<void> deleteCategory(CategoryModel cat) async {
    _logMethodStart('deleteCategory', {
      'categoryId': cat.id,
      'name': cat.name,
    });

    final menu = session.activeMenuFull;
    if (menu == null) {
      _log('deleteCategory skipped: no active menu');
      _logMethodDone('deleteCategory', {
        'skipped': true,
        'reason': 'no_active_menu',
      });
      return;
    }

    _setSaving(true);
    _setError(null);

    try {
      final res = await service.deleteCategory(
        businessId: businessId,
        menuId: menu.id,
        categoryId: cat.id,
      );
      _log('deleteCategory <- result=$res');

      final updatedCats = menu.categories.where((c) => c.id != cat.id).toList();
      session.updateActiveMenu(menu.copyWith(categories: updatedCats));
      _lastSyncAt = DateTime.now();

      _logMethodDone('deleteCategory', {
        'categoryId': cat.id,
      });
    } catch (e, st) {
      _setError(e.toString());
      _logMethodError('deleteCategory', e, st);
    } finally {
      _setSaving(false);
    }
  }

  // =========================================================
  // PRODUCT CRUD
  // =========================================================
  Future<void> createOrUpdateProduct({
    required CategoryModel category,
    required ProductModel product,
  }) async {
    _logMethodStart('createOrUpdateProduct', {
      'categoryId': category.id,
      'categoryName': category.name,
      'productId': product.id,
      'productName': product.name,
      'ingredientCount': product.ingredients.length,
      'optionGroupCount': product.optionGroups.length,
    });

    final menu = session.activeMenuFull;
    if (menu == null) {
      _log('createOrUpdateProduct skipped: no active menu');
      _logMethodDone('createOrUpdateProduct', {
        'skipped': true,
        'reason': 'no_active_menu',
      });
      return;
    }

    final name = product.name.trim();
    if (name.isEmpty) {
      _setError('Ürün adı boş olamaz.');
      _log('createOrUpdateProduct invalid: empty product name');
      return;
    }

    _setSaving(true);
    _setError(null);

    try {
      final sortOrder = category.products.indexWhere((p) => p.id == product.id);
      final resolvedSort = sortOrder >= 0 ? sortOrder : category.products.length;

      _log('createOrUpdateProduct resolvedSort=$resolvedSort');

      // 1) Ürün temel bilgileri
      _log('createOrUpdateProduct -> upsertProduct');
      final upsertRes = await service.upsertProduct(
        businessId: businessId,
        menuId: menu.id,
        categoryId: category.id,
        product: product,
        sortOrder: resolvedSort,
      );
      _log('createOrUpdateProduct <- upsertProduct result=$upsertRes');

      final savedProductId = (upsertRes['product_id'] ?? product.id).toString();
      _log('createOrUpdateProduct resolved savedProductId=$savedProductId');

      final serverSafeProduct = product.copyWith(id: savedProductId);

      // 2) Ingredient'ler
      _log('createOrUpdateProduct -> setProductIngredients count=${serverSafeProduct.ingredients.length}');
      final ingRes = await service.setProductIngredients(
        businessId: businessId,
        menuId: menu.id,
        productId: savedProductId,
        ingredients: serverSafeProduct.ingredients,
      );
      _log('createOrUpdateProduct <- setProductIngredients result=$ingRes');

      // 3) Option groups
      _log('createOrUpdateProduct -> setProductOptionGroups count=${serverSafeProduct.optionGroups.length}');
      final optRes = await service.setProductOptionGroups(
        businessId: businessId,
        menuId: menu.id,
        productId: savedProductId,
        optionGroups: serverSafeProduct.optionGroups,
      );
      _log('createOrUpdateProduct <- setProductOptionGroups result=$optRes');

      final updatedCats = menu.categories.map((c) {
        if (c.id != category.id) return c;

        final list = [...c.products];
        final idx = list.indexWhere((p) => p.id == product.id);
        if (idx >= 0) {
          list[idx] = serverSafeProduct;
        } else {
          list.add(serverSafeProduct);
        }

        return c.copyWith(products: list);
      }).toList();

      session.updateActiveMenu(menu.copyWith(categories: updatedCats));
      _lastSyncAt = DateTime.now();

      _logMethodDone('createOrUpdateProduct', {
        'productId': savedProductId,
        'categoryId': category.id,
        'ingredientCount': serverSafeProduct.ingredients.length,
        'optionGroupCount': serverSafeProduct.optionGroups.length,
      });
    } catch (e, st) {
      _setError(e.toString());
      _logMethodError('createOrUpdateProduct', e, st);
    } finally {
      _setSaving(false);
    }
  }

  Future<void> deleteProduct({
    required String productId,
  }) async {
    _logMethodStart('deleteProduct', {
      'productId': productId,
    });

    final menu = session.activeMenuFull;
    if (menu == null) {
      _log('deleteProduct skipped: no active menu');
      _logMethodDone('deleteProduct', {
        'skipped': true,
        'reason': 'no_active_menu',
      });
      return;
    }

    final id = productId.trim();
    if (id.isEmpty) {
      _log('deleteProduct skipped: empty productId');
      _logMethodDone('deleteProduct', {
        'skipped': true,
        'reason': 'empty_product_id',
      });
      return;
    }

    _setSaving(true);
    _setError(null);

    try {
      final res = await service.deleteProduct(
        businessId: businessId,
        menuId: menu.id,
        productId: id,
      );
      _log('deleteProduct <- result=$res');

      final updatedCats = menu.categories.map((c) {
        return c.copyWith(
          products: c.products.where((p) => p.id != id).toList(),
        );
      }).toList();

      session.updateActiveMenu(menu.copyWith(categories: updatedCats));
      _lastSyncAt = DateTime.now();

      _logMethodDone('deleteProduct', {
        'productId': id,
      });
    } catch (e, st) {
      _setError(e.toString());
      _logMethodError('deleteProduct', e, st);
    } finally {
      _setSaving(false);
    }
  }

  ProductModel? findProductById(String productId) {
    _log('findProductById START productId="$productId"');
    final menu = session.activeMenuFull;
    if (menu == null) {
      _log('findProductById no active menu');
      return null;
    }

    for (final c in menu.categories) {
      for (final p in c.products) {
        if (p.id == productId) {
          _log('findProductById HIT category="${c.name}" product="${p.name}"');
          return p;
        }
      }
    }

    _log('findProductById MISS productId="$productId"');
    return null;
  }

  // =========================================================
  // INGREDIENT LIBRARY
  // =========================================================
  Future<IngredientLibraryItem?> createOrUpdateIngredientLibraryItem(
      IngredientLibraryItem item,
      ) async {
    _logMethodStart('createOrUpdateIngredientLibraryItem', {
      'itemId': item.id,
      'name': item.name,
      'unit': item.unit.name,
    });

    final menu = session.activeMenuFull;
    if (menu == null) {
      _log('createOrUpdateIngredientLibraryItem skipped: no active menu');
      _logMethodDone('createOrUpdateIngredientLibraryItem', {
        'skipped': true,
        'reason': 'no_active_menu',
      });
      return null;
    }

    if (item.name.trim().isEmpty) {
      _setError('İçerik adı boş olamaz.');
      _log('createOrUpdateIngredientLibraryItem invalid: empty name');
      return null;
    }

    _setSaving(true);
    _setError(null);

    try {
      final res = await service.upsertIngredientLibraryItem(
        businessId: businessId,
        item: item,
      );
      _log('createOrUpdateIngredientLibraryItem <- result=$res');

      final list = [...menu.ingredientLibrary];
      final idx = list.indexWhere((x) => x.id == item.id);
      if (idx >= 0) {
        list[idx] = item;
      } else {
        list.add(item);
      }

      session.updateActiveMenu(menu.copyWith(ingredientLibrary: list));
      _lastSyncAt = DateTime.now();

      _logMethodDone('createOrUpdateIngredientLibraryItem', {
        'itemId': item.id,
      });
      return item;
    } catch (e, st) {
      _setError(e.toString());
      _logMethodError('createOrUpdateIngredientLibraryItem', e, st);
      return null;
    } finally {
      _setSaving(false);
    }
  }

  Future<void> deleteIngredientLibraryItem(String itemId) async {
    _logMethodStart('deleteIngredientLibraryItem', {
      'itemId': itemId,
    });

    final menu = session.activeMenuFull;
    if (menu == null) {
      _log('deleteIngredientLibraryItem skipped: no active menu');
      _logMethodDone('deleteIngredientLibraryItem', {
        'skipped': true,
        'reason': 'no_active_menu',
      });
      return;
    }

    final id = itemId.trim();
    if (id.isEmpty) {
      _log('deleteIngredientLibraryItem skipped: empty itemId');
      _logMethodDone('deleteIngredientLibraryItem', {
        'skipped': true,
        'reason': 'empty_item_id',
      });
      return;
    }

    _setSaving(true);
    _setError(null);

    try {
      final res = await service.deleteIngredientLibraryItem(
        businessId: businessId,
        itemId: id,
      );
      _log('deleteIngredientLibraryItem <- result=$res');

      var updated = menu.copyWith(
        ingredientLibrary: menu.ingredientLibrary.where((x) => x.id != id).toList(),
      );

      final updatedCats = updated.categories.map((cat) {
        final updatedProds = cat.products.map((p) {
          final nextRefs = p.ingredients.where((r) => r.ingredientId != id).toList();
          return p.copyWith(ingredients: nextRefs);
        }).toList();
        return cat.copyWith(products: updatedProds);
      }).toList();

      updated = updated.copyWith(categories: updatedCats);

      session.updateActiveMenu(updated);
      _lastSyncAt = DateTime.now();

      _logMethodDone('deleteIngredientLibraryItem', {
        'itemId': id,
      });
    } catch (e, st) {
      _setError(e.toString());
      _logMethodError('deleteIngredientLibraryItem', e, st);
    } finally {
      _setSaving(false);
    }
  }

  // =========================================================
  // COMBO
  // =========================================================
  Future<void> saveCombo(ComboDraft combo) async {
    _logMethodStart('saveCombo', {
      'comboId': combo.id,
      'name': combo.name,
      'itemCount': combo.items.length,
      'priceMode': combo.priceMode.name,
    });

    final menu = session.activeMenuFull;
    if (menu == null) {
      _log('saveCombo skipped: no active menu');
      _logMethodDone('saveCombo', {
        'skipped': true,
        'reason': 'no_active_menu',
      });
      return;
    }

    _setSaving(true);
    _setError(null);

    try {
      final res = await service.upsertCombo(
        businessId: businessId,
        menuId: menu.id,
        combo: combo,
      );
      _log('saveCombo <- result=$res');

      final list = [...menu.combos];
      final idx = list.indexWhere((x) => x.id == combo.id);
      if (idx >= 0) {
        list[idx] = combo;
      } else {
        list.add(combo);
      }

      session.updateActiveMenu(menu.copyWith(combos: list));
      _lastSyncAt = DateTime.now();

      _logMethodDone('saveCombo', {
        'comboId': combo.id,
      });
    } catch (e, st) {
      _setError(e.toString());
      _logMethodError('saveCombo', e, st);
    } finally {
      _setSaving(false);
    }
  }

  Future<void> deleteComboLocal(String comboId) async {
    _logMethodStart('deleteComboLocal', {
      'comboId': comboId,
    });

    final menu = session.activeMenuFull;
    if (menu == null) {
      _log('deleteComboLocal skipped: no active menu');
      _logMethodDone('deleteComboLocal', {
        'skipped': true,
        'reason': 'no_active_menu',
      });
      return;
    }

    _setSaving(true);
    _setError(null);

    try {
      final res = await service.deleteCombo(
        businessId: businessId,
        menuId: menu.id,
        comboId: comboId,
      );
      _log('deleteComboLocal <- result=$res');

      session.updateActiveMenu(
        menu.copyWith(
          combos: menu.combos.where((c) => c.id != comboId).toList(),
        ),
      );

      _lastSyncAt = DateTime.now();

      _logMethodDone('deleteComboLocal', {
        'comboId': comboId,
      });
    } catch (e, st) {
      _setError(e.toString());
      _logMethodError('deleteComboLocal', e, st);
    } finally {
      _setSaving(false);
    }
  }

  // =========================================================
  // EVENT
  // =========================================================
  Future<void> saveEvent(EventDraft event) async {
    _logMethodStart('saveEvent', {
      'eventId': event.id,
      'name': event.name,
      'scheduleType': event.scheduleType.name,
      'productCount': event.productIds.length,
    });

    final menu = session.activeMenuFull;
    if (menu == null) {
      _log('saveEvent skipped: no active menu');
      _logMethodDone('saveEvent', {
        'skipped': true,
        'reason': 'no_active_menu',
      });
      return;
    }

    _setSaving(true);
    _setError(null);

    try {
      final res = await service.upsertEvent(
        businessId: businessId,
        menuId: menu.id,
        event: event,
      );
      _log('saveEvent <- result=$res');

      final list = [...menu.events];
      final idx = list.indexWhere((x) => x.id == event.id);
      if (idx >= 0) {
        list[idx] = event;
      } else {
        list.add(event);
      }

      session.updateActiveMenu(menu.copyWith(events: list));
      _lastSyncAt = DateTime.now();

      _logMethodDone('saveEvent', {
        'eventId': event.id,
      });
    } catch (e, st) {
      _setError(e.toString());
      _logMethodError('saveEvent', e, st);
    } finally {
      _setSaving(false);
    }
  }

  Future<void> deleteEventLocal(String eventId) async {
    _logMethodStart('deleteEventLocal', {
      'eventId': eventId,
    });

    final menu = session.activeMenuFull;
    if (menu == null) {
      _log('deleteEventLocal skipped: no active menu');
      _logMethodDone('deleteEventLocal', {
        'skipped': true,
        'reason': 'no_active_menu',
      });
      return;
    }

    _setSaving(true);
    _setError(null);

    try {
      final res = await service.deleteEvent(
        businessId: businessId,
        menuId: menu.id,
        eventId: eventId,
      );
      _log('deleteEventLocal <- result=$res');

      session.updateActiveMenu(
        menu.copyWith(
          events: menu.events.where((e) => e.id != eventId).toList(),
        ),
      );

      _lastSyncAt = DateTime.now();

      _logMethodDone('deleteEventLocal', {
        'eventId': eventId,
      });
    } catch (e, st) {
      _setError(e.toString());
      _logMethodError('deleteEventLocal', e, st);
    } finally {
      _setSaving(false);
    }
  }

  // =========================================================
  // STATE HELPERS
  // =========================================================
  void clearError() {
    _log('clearError oldError=$_error');
    _setError(null);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _log('_setLoading -> $value');
    notifyListeners();
  }

  void _setSaving(bool value) {
    _isSaving = value;
    _log('_setSaving -> $value');
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    _log('_setError -> $value');
    notifyListeners();
  }
}