// lib/services/menu_service.dart
//
// ✅ Yeni mimari: 1 kez full çek -> sonra her şeyi “tek tek” RPC ile anında yaz.
// - Menu/Category/Product/Ingredient/Combo/Event ayrı ayrı kaydolur.
// - Büyük “menu tree” payload’ı göndermiyoruz (gereksiz maliyet + risk).
//
// ✅ İstediğin değişiklikler:
// 1) Create/Update ayrımı yok -> her şey UPSERT
// 2) RPC isimlerinden "menu_" prefix’i kaldırıldı:
//    upsert_menu, delete_menu, upsert_category, delete_category, upsert_product, delete_product, ...
//
// Not: SQL’de RPC isimlerini de birebir bunlara göre rename etmelisin.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/panel/menu/menu_models.dart';

class MenuService {
  final SupabaseClient _sb;
  MenuService(this._sb);

  void _log(String msg) => debugPrint('[MenuService] $msg');

  // =========================================================
  // RPC NAMES (single source of truth)
  // =========================================================

  // Fetch (değişmedi)
  static const String rpcFetchMenusLight = 'fetch_menus_light';
  static const String rpcFetchMenuFull = 'fetch_menu_full';

  // ✅ Yeni: “tek tek upsert/delete” RPC’leri
  static const String rpcUpsertMenu = 'upsert_menu'; // (p_business_id, p_menu)
  static const String rpcDeleteMenu = 'delete_menu'; // (p_business_id, p_menu_id)

  static const String rpcUpsertCategory = 'upsert_category'; // (p_business_id, p_menu_id, p_category)
  static const String rpcDeleteCategory = 'delete_category'; // (p_business_id, p_menu_id, p_category_id)

  static const String rpcUpsertProduct = 'upsert_product'; // (p_business_id, p_menu_id, p_category_id, p_product)
  static const String rpcDeleteProduct = 'delete_product'; // (p_business_id, p_menu_id, p_product_id)

  // Ingredient Library item: business scoped
  static const String rpcUpsertIngredientLibraryItem =
      'upsert_ingredient_library_item'; // (p_business_id, p_item)
  static const String rpcDeleteIngredientLibraryItem =
      'delete_ingredient_library_item'; // (p_business_id, p_item_id)

  // Product -> ingredients replace (tek hamlede listeyi set et)
  static const String rpcSetProductIngredients =
      'set_product_ingredients'; // (p_business_id, p_menu_id, p_product_id, p_ingredients)

  // Combo/Event
  static const String rpcUpsertCombo = 'upsert_combo';
  static const String rpcUpsertEvent = 'upsert_event';
  static const String rpcDeleteCombo = 'delete_combo';
  static const String rpcDeleteEvent = 'delete_event';

  // =========================================================
  // FETCH LIGHT LIST
  // RPC: fetch_menus_light(p_business_id uuid) -> { ok, menus: [] }
  // =========================================================
  Future<List<MenuModel>> fetchMenusLight({
    required String businessId,
  }) async {
    final bId = businessId.trim();
    _log('fetchMenusLight START businessId="$bId"');

    final res = await _sb.rpc(rpcFetchMenusLight, params: {
      'p_business_id': bId,
    });

    final json = (res as Map).cast<String, dynamic>();
    final ok = json['ok'] == true;
    if (!ok) {
      final reason = (json['reason'] ?? 'fetch_menus_light_failed').toString();
      throw Exception('Menüler alınamadı: $reason');
    }

    final rawList = (json['menus'] as List?) ?? const [];
    final list = <MenuModel>[];

    for (final r in rawList) {
      final m = (r as Map).cast<String, dynamic>();
      list.add(
        MenuModel(
          id: (m['id'] ?? '').toString(),
          businessId: (m['business_id'] ?? '').toString(),
          name: (m['name'] ?? '').toString(),
          categories: const [],
          ingredientLibrary: const [],
          combos: const [],
          events: const [],
        ),
      );
    }

    _log('fetchMenusLight DONE count=${list.length}');
    return list;
  }

  // =========================================================
  // FETCH FULL MENU
  // RPC: fetch_menu_full(p_business_id uuid, p_menu_id uuid)
  // -> { ok, menu: {...full tree...} }
  // =========================================================
  Future<MenuModel> fetchMenuFull({
    required String businessId,
    required String menuId,
  }) async {
    final bId = businessId.trim();
    final mId = menuId.trim();
    _log('fetchMenuFull START businessId="$bId" menuId="$mId"');

    final res = await _sb.rpc(rpcFetchMenuFull, params: {
      'p_business_id': bId,
      'p_menu_id': mId,
    });

    final json = (res as Map).cast<String, dynamic>();
    final ok = json['ok'] == true;
    if (!ok) {
      final reason = (json['reason'] ?? 'fetch_menu_full_failed').toString();
      throw Exception('Menü alınamadı: $reason');
    }

    final tree = (json['menu'] as Map?)?.cast<String, dynamic>();
    if (tree == null) throw Exception('RPC "menu" missing');

    final model = MenuModel.fromJson(tree);
    _log(
      'fetchMenuFull DONE id=${model.id} name="${model.name}" '
          'cats=${model.categories.length} lib=${model.ingredientLibrary.length} '
          'combos=${model.combos.length} events=${model.events.length}',
    );
    return model;
  }

  // =========================================================
  // ✅ MENU UPSERT (anında)
  // RPC: upsert_menu(p_business_id, p_menu)
  // -> { ok, menu_id }
  // =========================================================
  Future<Map<String, dynamic>> upsertMenu({
    required String businessId,
    required MenuModel menu,
  }) async {
    final bId = businessId.trim();

    // Menü payload: combos/events burada göndermiyoruz (combo/event ayrı tablolar)
    final pMenu = <String, dynamic>{
      'id': menu.id,
      'name': menu.name,
      // 'is_active': true,
    };

    _log('upsertMenu START businessId="$bId" menuId="${menu.id}"');

    final res = await _sb.rpc(rpcUpsertMenu, params: {
      'p_business_id': bId,
      'p_menu': pMenu,
    });

    final json = (res as Map).cast<String, dynamic>();
    final ok = json['ok'] == true;
    if (!ok) {
      throw Exception((json['reason'] ?? 'upsert_menu_failed').toString());
    }

    _log('upsertMenu DONE menu_id=${json['menu_id']}');
    return json;
  }

  Future<Map<String, dynamic>> deleteMenu({
    required String businessId,
    required String menuId,
  }) async {
    final bId = businessId.trim();
    final mId = menuId.trim();

    _log('deleteMenu START businessId="$bId" menuId="$mId"');

    final res = await _sb.rpc(rpcDeleteMenu, params: {
      'p_business_id': bId,
      'p_menu_id': mId,
    });

    final json = (res as Map).cast<String, dynamic>();
    final ok = json['ok'] == true;
    if (!ok) throw Exception((json['reason'] ?? 'delete_menu_failed').toString());

    _log('deleteMenu DONE ok=$ok');
    return json;
  }

  // =========================================================
  // ✅ CATEGORY UPSERT (anında)
  // RPC: upsert_category(p_business_id, p_menu_id, p_category)
  // =========================================================
  Future<Map<String, dynamic>> upsertCategory({
    required String businessId,
    required String menuId,
    required CategoryModel category,
    int? sortOrder,
  }) async {
    final bId = businessId.trim();
    final mId = menuId.trim();

    final pCategory = <String, dynamic>{
      'id': category.id,
      'name': category.name,
      if (sortOrder != null) 'sort_order': sortOrder,
    };

    _log('upsertCategory START businessId="$bId" menuId="$mId" catId="${category.id}"');

    final res = await _sb.rpc(rpcUpsertCategory, params: {
      'p_business_id': bId,
      'p_menu_id': mId,
      'p_category': pCategory,
    });

    final json = (res as Map).cast<String, dynamic>();
    final ok = json['ok'] == true;
    if (!ok) throw Exception((json['reason'] ?? 'upsert_category_failed').toString());

    _log('upsertCategory DONE ok=$ok');
    return json;
  }

  Future<Map<String, dynamic>> deleteCategory({
    required String businessId,
    required String menuId,
    required String categoryId,
  }) async {
    final bId = businessId.trim();
    final mId = menuId.trim();
    final cId = categoryId.trim();

    _log('deleteCategory START businessId="$bId" menuId="$mId" categoryId="$cId"');

    final res = await _sb.rpc(rpcDeleteCategory, params: {
      'p_business_id': bId,
      'p_menu_id': mId,
      'p_category_id': cId,
    });

    final json = (res as Map).cast<String, dynamic>();
    final ok = json['ok'] == true;
    if (!ok) throw Exception((json['reason'] ?? 'delete_category_failed').toString());

    _log('deleteCategory DONE ok=$ok');
    return json;
  }

  // =========================================================
  // ✅ PRODUCT UPSERT (anında)
  // RPC: upsert_product(p_business_id, p_menu_id, p_category_id, p_product)
  // =========================================================
  Future<Map<String, dynamic>> upsertProduct({
    required String businessId,
    required String menuId,
    required String categoryId,
    required ProductModel product,
    int? sortOrder,
  }) async {
    final bId = businessId.trim();
    final mId = menuId.trim();
    final cId = categoryId.trim();

    final pProduct = <String, dynamic>{
      'id': product.id,
      'name': product.name,
      'description': product.description,
      'price': product.price,
      'image_url': product.imageUrl,
      if (sortOrder != null) 'sort_order': sortOrder,
      // 'is_available': true,
    };

    _log('upsertProduct START businessId="$bId" menuId="$mId" categoryId="$cId" productId="${product.id}"');

    final res = await _sb.rpc(rpcUpsertProduct, params: {
      'p_business_id': bId,
      'p_menu_id': mId,
      'p_category_id': cId,
      'p_product': pProduct,
    });

    final json = (res as Map).cast<String, dynamic>();
    final ok = json['ok'] == true;
    if (!ok) throw Exception((json['reason'] ?? 'upsert_product_failed').toString());

    _log('upsertProduct DONE ok=$ok');
    return json;
  }

  Future<Map<String, dynamic>> deleteProduct({
    required String businessId,
    required String menuId,
    required String productId,
  }) async {
    final bId = businessId.trim();
    final mId = menuId.trim();
    final pId = productId.trim();

    _log('deleteProduct START businessId="$bId" menuId="$mId" productId="$pId"');

    final res = await _sb.rpc(rpcDeleteProduct, params: {
      'p_business_id': bId,
      'p_menu_id': mId,
      'p_product_id': pId,
    });

    final json = (res as Map).cast<String, dynamic>();
    final ok = json['ok'] == true;
    if (!ok) throw Exception((json['reason'] ?? 'delete_product_failed').toString());

    _log('deleteProduct DONE ok=$ok');
    return json;
  }

  // =========================================================
  // ✅ INGREDIENT LIBRARY ITEM UPSERT (anında)
  // RPC: upsert_ingredient_library_item(p_business_id, p_item)
  // =========================================================
  Future<Map<String, dynamic>> upsertIngredientLibraryItem({
    required String businessId,
    required IngredientLibraryItem item,
  }) async {
    final bId = businessId.trim();

    final pItem = <String, dynamic>{
      'id': item.id,
      'name': item.name,
      'unit': item.unit.name, // gr/ml/adet
      'note': item.note,
      // 'is_active': true,
    };

    _log('upsertIngredientLibraryItem START businessId="$bId" itemId="${item.id}" name="${item.name}"');

    final res = await _sb.rpc(rpcUpsertIngredientLibraryItem, params: {
      'p_business_id': bId,
      'p_item': pItem,
    });

    final json = (res as Map).cast<String, dynamic>();
    final ok = json['ok'] == true;
    if (!ok) throw Exception((json['reason'] ?? 'upsert_ingredient_library_item_failed').toString());

    _log('upsertIngredientLibraryItem DONE ok=$ok item_id=${json['item_id']}');
    return json;
  }

  Future<Map<String, dynamic>> deleteIngredientLibraryItem({
    required String businessId,
    required String itemId,
  }) async {
    final bId = businessId.trim();
    final iId = itemId.trim();

    _log('deleteIngredientLibraryItem START businessId="$bId" itemId="$iId"');

    final res = await _sb.rpc(rpcDeleteIngredientLibraryItem, params: {
      'p_business_id': bId,
      'p_item_id': iId,
    });

    final json = (res as Map).cast<String, dynamic>();
    final ok = json['ok'] == true;
    if (!ok) throw Exception((json['reason'] ?? 'delete_ingredient_library_item_failed').toString());

    _log('deleteIngredientLibraryItem DONE ok=$ok');
    return json;
  }

  // =========================================================
  // ✅ PRODUCT INGREDIENTS SET (replace list) (anında)
  // RPC: set_product_ingredients(p_business_id, p_menu_id, p_product_id, p_ingredients)
  // =========================================================
  Future<Map<String, dynamic>> setProductIngredients({
    required String businessId,
    required String menuId,
    required String productId,
    required List<ProductIngredientRef> ingredients,
  }) async {
    final bId = businessId.trim();
    final mId = menuId.trim();
    final pId = productId.trim();

    final pIngredients = ingredients
        .map((r) => {
      'ingredientId': r.ingredientId,
      'amount': r.amount,
      if (r.unitOverride != null) 'unitOverride': r.unitOverride!.name,
    })
        .toList();

    _log('setProductIngredients START businessId="$bId" menuId="$mId" productId="$pId" count=${pIngredients.length}');

    final res = await _sb.rpc(rpcSetProductIngredients, params: {
      'p_business_id': bId,
      'p_menu_id': mId,
      'p_product_id': pId,
      'p_ingredients': pIngredients,
    });

    final json = (res as Map).cast<String, dynamic>();
    final ok = json['ok'] == true;
    if (!ok) throw Exception((json['reason'] ?? 'set_product_ingredients_failed').toString());

    _log('setProductIngredients DONE ok=$ok');
    return json;
  }

  // =========================================================
  // ✅ COMBO / EVENT UPSERT/DELETE (anında)
  // =========================================================
  Future<Map<String, dynamic>> upsertCombo({
    required String businessId,
    required String menuId,
    required ComboDraft combo,
  }) async {
    final bId = businessId.trim();
    final mId = menuId.trim();

    _log('upsertCombo START businessId="$bId" menuId="$mId" comboId="${combo.id}"');

    final res = await _sb.rpc(rpcUpsertCombo, params: {
      'p_business_id': bId,
      'p_menu_id': mId,
      'p_combo': combo.toJson(),
    });

    final json = (res as Map).cast<String, dynamic>();
    final ok = json['ok'] == true;
    if (!ok) throw Exception((json['reason'] ?? 'upsert_combo_failed').toString());

    _log('upsertCombo DONE ok=$ok');
    return json;
  }

  Future<Map<String, dynamic>> upsertEvent({
    required String businessId,
    required String menuId,
    required EventDraft event,
  }) async {
    final bId = businessId.trim();
    final mId = menuId.trim();

    _log('upsertEvent START businessId="$bId" menuId="$mId" eventId="${event.id}"');

    final res = await _sb.rpc(rpcUpsertEvent, params: {
      'p_business_id': bId,
      'p_menu_id': mId,
      'p_event': event.toJson(),
    });

    final json = (res as Map).cast<String, dynamic>();
    final ok = json['ok'] == true;
    if (!ok) throw Exception((json['reason'] ?? 'upsert_event_failed').toString());

    _log('upsertEvent DONE ok=$ok');
    return json;
  }

  Future<Map<String, dynamic>> deleteCombo({
    required String businessId,
    required String menuId,
    required String comboId,
  }) async {
    final bId = businessId.trim();
    final mId = menuId.trim();
    final cId = comboId.trim();

    _log('deleteCombo START businessId="$bId" menuId="$mId" comboId="$cId"');

    final res = await _sb.rpc(rpcDeleteCombo, params: {
      'p_business_id': bId,
      'p_menu_id': mId,
      'p_combo_id': cId,
    });

    final json = (res as Map).cast<String, dynamic>();
    final ok = json['ok'] == true;
    if (!ok) throw Exception((json['reason'] ?? 'delete_combo_failed').toString());

    _log('deleteCombo DONE ok=$ok');
    return json;
  }

  Future<Map<String, dynamic>> deleteEvent({
    required String businessId,
    required String menuId,
    required String eventId,
  }) async {
    final bId = businessId.trim();
    final mId = menuId.trim();
    final eId = eventId.trim();

    _log('deleteEvent START businessId="$bId" menuId="$mId" eventId="$eId"');

    final res = await _sb.rpc(rpcDeleteEvent, params: {
      'p_business_id': bId,
      'p_menu_id': mId,
      'p_event_id': eId,
    });

    final json = (res as Map).cast<String, dynamic>();
    final ok = json['ok'] == true;
    if (!ok) throw Exception((json['reason'] ?? 'delete_event_failed').toString());

    _log('deleteEvent DONE ok=$ok');
    return json;
  }

  // =========================================================
  // IMAGE UPLOAD (Supabase Storage)
  // Bucket: menu-product-images
  // =========================================================
  Future<String> uploadProductImage({
    required String businessId,
    required String menuId,
    required String productId,
    required String localPath,
  }) async {
    final bId = businessId.trim();
    final mId = menuId.trim();
    final pId = productId.trim();
    final lp = localPath.trim();

    _log('uploadProductImage START businessId="$bId" menuId="$mId" productId="$pId" path="$lp"');

    try {
      final file = File(lp);
      if (!await file.exists()) {
        throw Exception('Local image not found: $lp');
      }

      final bytes = await file.readAsBytes();
      final ext = _safeExt(lp);
      final contentType = _contentTypeForExt(ext);

      final path = '$bId/$mId/$pId.$ext';

      await _sb.storage.from('menu-product-images').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: contentType,
        ),
      );

      final url = _sb.storage.from('menu-product-images').getPublicUrl(path);
      _log('uploadProductImage DONE url="$url"');
      return url;
    } catch (e, st) {
      _log('uploadProductImage ERROR=$e');
      _log('stack=$st');
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // helpers
  // ---------------------------------------------------------
  String _safeExt(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    if (lower.endsWith('.jpeg')) return 'jpeg';
    return 'jpg';
  }

  String _contentTypeForExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  // Debug için payload clip
  String clipJson(Object obj, {int max = 1200}) {
    final pretty = const JsonEncoder.withIndent('  ').convert(obj);
    if (pretty.length <= max) return pretty;
    return '${pretty.substring(0, max)}\n…[clipped ${pretty.length - max} chars]…';
  }
}