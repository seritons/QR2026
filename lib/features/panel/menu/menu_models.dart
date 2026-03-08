import 'dart:convert';
import 'package:flutter/material.dart';

import 'dart:convert';

// ------------------------------------------------------------
// OPTION SELECT TYPE
// ------------------------------------------------------------
enum OptionSelectType { single, multi }

extension OptionSelectTypeX on OptionSelectType {
  String get label {
    switch (this) {
      case OptionSelectType.single:
        return 'Tek seçim';
      case OptionSelectType.multi:
        return 'Çoklu seçim';
    }
  }
}

// ------------------------------------------------------------
// PRODUCT OPTION ITEM
// ------------------------------------------------------------
class ProductOptionItem {
  final String id;
  final String name;
  final double priceDelta; // + fiyat farkı, 0 = ücretsiz

  const ProductOptionItem({
    required this.id,
    required this.name,
    required this.priceDelta,
  });

  ProductOptionItem copyWith({
    String? id,
    String? name,
    double? priceDelta,
  }) {
    return ProductOptionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      priceDelta: priceDelta ?? this.priceDelta,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'priceDelta': priceDelta,
  };

  factory ProductOptionItem.fromJson(Map<String, dynamic> json) {
    return ProductOptionItem(
      id: json['id'] as String,
      name: (json['name'] ?? '') as String,
      priceDelta: (json['priceDelta'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ------------------------------------------------------------
// PRODUCT OPTION GROUP
// ------------------------------------------------------------
class ProductOptionGroup {
  final String id;
  final String title;

  /// seçim kuralı
  final OptionSelectType selectType;

  /// seçilebilir adet kuralları
  final int minSelect; // 0 veya 1 çoğu senaryo
  final int maxSelect; // single ise genelde 1

  final List<ProductOptionItem> options;

  const ProductOptionGroup({
    required this.id,
    required this.title,
    required this.selectType,
    required this.minSelect,
    required this.maxSelect,
    required this.options,
  });

  ProductOptionGroup copyWith({
    String? id,
    String? title,
    OptionSelectType? selectType,
    int? minSelect,
    int? maxSelect,
    List<ProductOptionItem>? options,
  }) {
    return ProductOptionGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      selectType: selectType ?? this.selectType,
      minSelect: minSelect ?? this.minSelect,
      maxSelect: maxSelect ?? this.maxSelect,
      options: options ?? this.options,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'selectType': selectType.name,
    'minSelect': minSelect,
    'maxSelect': maxSelect,
    'options': options.map((e) => e.toJson()).toList(),
  };

  factory ProductOptionGroup.fromJson(Map<String, dynamic> json) {
    final selectTypeStr = (json['selectType'] ?? 'single') as String;
    final type = OptionSelectType.values.firstWhere(
          (e) => e.name == selectTypeStr,
      orElse: () => OptionSelectType.single,
    );

    return ProductOptionGroup(
      id: json['id'] as String,
      title: (json['title'] ?? '') as String,
      selectType: type,
      minSelect: (json['minSelect'] as num?)?.toInt() ?? 0,
      maxSelect: (json['maxSelect'] as num?)?.toInt() ?? 1,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => ProductOptionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ------------------------------------------------------------
// PRODUCT INGREDIENT REF (unitOverride nullable olmalı)
// Çünkü UI’da "ref.unitOverride ?? it.unit" yapıyorsun.
// ------------------------------------------------------------
class ProductIngredientRef {
  final String ingredientId;
  final double amount;

  /// null ise ingredientLibraryItem.unit kullanılır
  final IngredientUnit? unitOverride;

  const ProductIngredientRef({
    required this.ingredientId,
    required this.amount,
    this.unitOverride,
  });

  ProductIngredientRef copyWith({
    String? ingredientId,
    double? amount,
    IngredientUnit? unitOverride,
    bool setUnitOverride = false,
  }) {
    return ProductIngredientRef(
      ingredientId: ingredientId ?? this.ingredientId,
      amount: amount ?? this.amount,
      unitOverride: setUnitOverride ? unitOverride : (unitOverride ?? this.unitOverride),
    );
  }

  Map<String, dynamic> toJson() => {
    'ingredientId': ingredientId,
    'amount': amount,
    'unitOverride': unitOverride?.name,
  };

  factory ProductIngredientRef.fromJson(Map<String, dynamic> json) {
    final u = json['unitOverride'];
    IngredientUnit? unit;
    if (u is String && u.isNotEmpty) {
      unit = IngredientUnit.values.firstWhere(
            (e) => e.name == u,
        orElse: () => IngredientUnit.adet,
      );
    }

    return ProductIngredientRef(
      ingredientId: json['ingredientId'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      unitOverride: unit,
    );
  }
}

// ------------------------------------------------------------
// PRODUCT MODEL (optionGroups eklendi + JSON)
// ------------------------------------------------------------
class ProductModel {
  final String id;
  final String name;
  final String description;
  final String? imageUrl; // ➕ Yeni alan
  final double price;
  final List<ProductIngredientRef> ingredients;
  final List<ProductOptionGroup> optionGroups;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl, // ➕ Gerekli kılındı
    required this.price,
    required this.ingredients,
    this.optionGroups = const [],
  });

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    double? price,
    List<ProductIngredientRef>? ingredients,
    List<ProductOptionGroup>? optionGroups,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      ingredients: ingredients ?? this.ingredients,
      optionGroups: optionGroups ?? this.optionGroups,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'price': price,
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'optionGroups': optionGroups.map((e) => e.toJson()).toList(),
  };

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: (json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      imageUrl: (json['imageUrl'] ?? '') as String, // ➕ Mapping
      price: (json['price'] as num?)?.toDouble() ?? 0,
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((e) => ProductIngredientRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      optionGroups: (json['optionGroups'] as List<dynamic>? ?? [])
          .map((e) => ProductOptionGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String toRawJson() => jsonEncode(toJson());
  factory ProductModel.fromRawJson(String s) =>
      ProductModel.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
// --------------------------
// Ingredient modellerin aynen kalsın
// --------------------------
enum IngredientUnit { gr, ml, adet }

extension IngredientUnitLabel on IngredientUnit {
  String get label {
    switch (this) {
      case IngredientUnit.gr:
        return 'gr';
      case IngredientUnit.ml:
        return 'ml';
      case IngredientUnit.adet:
        return 'adet';
    }
  }
}

class IngredientLibraryItem {
  final String id; // uuid/tmp
  final String name;
  final IngredientUnit unit;
  final String? note;

  const IngredientLibraryItem({
    required this.id,
    required this.name,
    required this.unit,
    this.note,
  });

  IngredientLibraryItem copyWith({
    String? id,
    String? name,
    IngredientUnit? unit,
    String? note,
  }) {
    return IngredientLibraryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'unit': unit.name,
    'note': note,
  };

  factory IngredientLibraryItem.fromJson(Map<String, dynamic> json) {
    final u = (json['unit'] ?? 'gr').toString();
    return IngredientLibraryItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      unit: IngredientUnit.values.firstWhere(
            (e) => e.name == u,
        orElse: () => IngredientUnit.gr,
      ),
      note: json['note']?.toString(),
    );
  }
}
// ==========================================================
// ✅ MÜŞTERİ SEÇİMLERİ (Product Options)
// ==========================================================

enum ProductOptionGroupType { single, multi }

extension ProductOptionGroupTypeLabel on ProductOptionGroupType {
  String get label => switch (this) {
    ProductOptionGroupType.single => 'Tek seçim',
    ProductOptionGroupType.multi => 'Çoklu seçim',
  };
}

/// Bir cevap: "Az pişmiş", "Ekstra köfte (+30₺)" gibi
class ProductOptionChoice {
  final String id; // tmp_...
  final String label;
  final double priceDelta; // + ücret (0 ücretsiz)

  const ProductOptionChoice({
    required this.id,
    required this.label,
    required this.priceDelta,
  });

  ProductOptionChoice copyWith({
    String? id,
    String? label,
    double? priceDelta,
  }) {
    return ProductOptionChoice(
      id: id ?? this.id,
      label: label ?? this.label,
      priceDelta: priceDelta ?? this.priceDelta,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'priceDelta': priceDelta,
  };

  factory ProductOptionChoice.fromJson(Map<String, dynamic> json) {
    return ProductOptionChoice(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      priceDelta: (json['priceDelta'] is num) ? (json['priceDelta'] as num).toDouble() : 0.0,
    );
  }
}

// ==========================================================
// ✅ PRODUCT MODEL (Extras kaldırıldı, options eklendi)
// ==========================================================
IngredientUnit ingredientUnitFromString(String s) {
  switch (s) {
    case 'gr':
      return IngredientUnit.gr;
    case 'ml':
      return IngredientUnit.ml;
    case 'adet':
      return IngredientUnit.adet;
    default:
      return IngredientUnit.gr;
  }
}

class ProductExtraRef {
  /// Ekstra olarak seçilebilecek ürünün id'si (ProductModel.id)
  final String extraProductId;

  /// MVP: genelde 1 (örn: 1 adet patates).
  /// İleride: 0..N (örn: 2x sos) gibi kullanılabilir.
  final int maxQty;

  /// UI sıralaması
  final int sort;

  /// UI-only cache (serialize edilmez): resolve edilmiş ürün
  final ProductModel? extraProduct;

  const ProductExtraRef({
    required this.extraProductId,
    this.maxQty = 1,
    this.sort = 0,
    this.extraProduct,
  });

  ProductExtraRef copyWith({
    String? extraProductId,
    int? maxQty,
    int? sort,
    ProductModel? extraProduct,
    bool setExtraProduct = false,
  }) {
    return ProductExtraRef(
      extraProductId: extraProductId ?? this.extraProductId,
      maxQty: maxQty ?? this.maxQty,
      sort: sort ?? this.sort,
      extraProduct: setExtraProduct ? extraProduct : this.extraProduct,
    );
  }

  Map<String, dynamic> toJson() => {
    'extraProductId': extraProductId,
    'maxQty': maxQty,
    'sort': sort,
  };

  factory ProductExtraRef.fromJson(Map<String, dynamic> json) {
    return ProductExtraRef(
      extraProductId: (json['extraProductId'] ?? '').toString(),
      maxQty: (json['maxQty'] is num) ? (json['maxQty'] as num).toInt() : 1,
      sort: (json['sort'] is num) ? (json['sort'] as num).toInt() : 0,
      extraProduct: null, // UI sonra resolve eder
    );
  }
}

// ==========================================================
// PRODUCT / CATEGORY / MENU
// ==========================================================

class CategoryModel {
  final String id;
  final String name;
  final List<ProductModel> products;

  const CategoryModel({
    required this.id,
    required this.name,
    this.products = const [],
  });

  CategoryModel copyWith({
    String? name,
    List<ProductModel>? products,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      products: products ?? this.products,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'products': products.map((e) => e.toJson()).toList(),
  };

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final prods = (json['products'] as List?)
        ?.map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
        .toList() ??
        const <ProductModel>[];

    return CategoryModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      products: prods,
    );
  }
}

class MenuModel {
  final String id;
  final String businessId;
  final String name;

  final List<CategoryModel> categories;
  final List<IngredientLibraryItem> ingredientLibrary;

  final List<ComboDraft> combos;
  final List<EventDraft> events;

  const MenuModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.categories = const [],
    this.ingredientLibrary = const [],
    this.combos = const [],
    this.events = const [],
  });

  MenuModel copyWith({
    String? name,
    List<CategoryModel>? categories,
    List<IngredientLibraryItem>? ingredientLibrary,
    List<ComboDraft>? combos,
    List<EventDraft>? events,
  }) {
    return MenuModel(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      categories: categories ?? this.categories,
      ingredientLibrary: ingredientLibrary ?? this.ingredientLibrary,
      combos: combos ?? this.combos,
      events: events ?? this.events,
    );
  }

  // ==========================================================
  // TO JSON
  // ==========================================================

  /// light=true => sadece temel alanlar (list view vs.)
  Map<String, dynamic> toJson({bool light = false}) {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      if (!light) 'categories': categories.map((e) => e.toJson()).toList(),
      if (!light) 'ingredient_library': ingredientLibrary.map((e) => e.toJson()).toList(),
      if (!light) 'combos': combos.map((e) => e.toJson()).toList(),
      if (!light) 'events': events.map((e) => e.toJson()).toList(),
    };
  }

  // ==========================================================
  // FROM JSON
  // ==========================================================

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: (json['id'] ?? '').toString(),
      businessId: (json['business_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      categories: (json['categories'] as List?)
          ?.map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList() ??
          const [],
      ingredientLibrary: (json['ingredient_library'] as List?)
          ?.map((e) => IngredientLibraryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList() ??
          const [],
      combos: (json['combos'] as List?)
          ?.map((e) => ComboDraft.fromJson(Map<String, dynamic>.from(e)))
          .toList() ??
          const [],
      events: (json['events'] as List?)
          ?.map((e) => EventDraft.fromJson(Map<String, dynamic>.from(e)))
          .toList() ??
          const [],
    );
  }
}

// ==========================================================
// PROMOTION TARGET (Event içinde ürün + combo hedeflemek)
// ==========================================================

enum PromotionTargetType { product, combo }

extension PromotionTargetTypeKey on PromotionTargetType {
  String get key => switch (this) {
    PromotionTargetType.product => 'product',
    PromotionTargetType.combo => 'combo',
  };
}

PromotionTargetType promotionTargetTypeFromString(String s) {
  switch (s) {
    case 'product':
      return PromotionTargetType.product;
    case 'combo':
      return PromotionTargetType.combo;
    default:
      return PromotionTargetType.product;
  }
}

class PromotionTargetRef {
  final PromotionTargetType type;
  final String id; // product_id OR combo_id

  const PromotionTargetRef({
    required this.type,
    required this.id,
  });

  Map<String, dynamic> toJson() => {
    'type': type.key,
    'id': id,
  };

  factory PromotionTargetRef.fromJson(Map<String, dynamic> json) {
    return PromotionTargetRef(
      type: promotionTargetTypeFromString((json['type'] ?? 'product').toString()),
      id: (json['id'] ?? '').toString(),
    );
  }
}

// ==========================================================
// COMBO (paket ürün gibi)
// ==========================================================

enum ComboPricingType { fixedPrice, percentOff, amountOff }

extension ComboPricingTypeKey on ComboPricingType {
  String get key => switch (this) {
    ComboPricingType.fixedPrice => 'fixed_price',
    ComboPricingType.percentOff => 'percent_off',
    ComboPricingType.amountOff => 'amount_off',
  };
}

ComboPricingType comboPricingTypeFromString(String s) {
  switch (s) {
    case 'fixed_price':
      return ComboPricingType.fixedPrice;
    case 'percent_off':
      return ComboPricingType.percentOff;
    case 'amount_off':
      return ComboPricingType.amountOff;
    default:
      return ComboPricingType.fixedPrice;
  }
}

/// Combo içindeki ürün referansı (miktar istersen)
class ComboItemRef {
  final String productId;
  final int qty;

  const ComboItemRef({
    required this.productId,
    this.qty = 1,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'qty': qty,
  };

  factory ComboItemRef.fromJson(Map<String, dynamic> json) {
    return ComboItemRef(
      productId: (json['productId'] ?? '').toString(),
      qty: (json['qty'] is num) ? (json['qty'] as num).toInt() : 1,
    );
  }
}

/// Combo = tek ürün gibi
/// - UI'da product card gibi gösterilir
/// - Event target listesine combo da eklenebilir
class ComboModel {
  final String id;
  final String businessId;

  final String name;
  final String description;

  /// Combo içeriği
  final List<ComboItemRef> items;

  /// Combo fiyat kuralı
  final ComboPricingType pricingType;

  /// fixedPrice: bundlePrice kullan
  /// percentOff: percent kullan
  /// amountOff: amount kullan
  final double? bundlePrice;
  final double? percent;
  final double? amount;

  final bool isActive;

  const ComboModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.description = '',
    this.items = const [],
    this.pricingType = ComboPricingType.fixedPrice,
    this.bundlePrice,
    this.percent,
    this.amount,
    this.isActive = true,
  });

  ComboModel copyWith({
    String? name,
    String? description,
    List<ComboItemRef>? items,
    ComboPricingType? pricingType,
    double? bundlePrice,
    bool setBundlePrice = false,
    double? percent,
    bool setPercent = false,
    double? amount,
    bool setAmount = false,
    bool? isActive,
  }) {
    return ComboModel(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      description: description ?? this.description,
      items: items ?? this.items,
      pricingType: pricingType ?? this.pricingType,
      bundlePrice: setBundlePrice ? bundlePrice : this.bundlePrice,
      percent: setPercent ? percent : this.percent,
      amount: setAmount ? amount : this.amount,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'businessId': businessId,
    'name': name,
    'description': description,
    'items': items.map((e) => e.toJson()).toList(),
    'pricingType': pricingType.key,
    'bundlePrice': bundlePrice,
    'percent': percent,
    'amount': amount,
    'isActive': isActive,
  };

  factory ComboModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['items'] as List?) ?? const [];
    final items = raw
        .whereType<Map>()
        .map((e) => ComboItemRef.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return ComboModel(
      id: (json['id'] ?? '').toString(),
      businessId: (json['businessId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      items: items,
      pricingType: comboPricingTypeFromString((json['pricingType'] ?? 'fixed_price').toString()),
      bundlePrice: (json['bundlePrice'] is num) ? (json['bundlePrice'] as num).toDouble() : null,
      percent: (json['percent'] is num) ? (json['percent'] as num).toDouble() : null,
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : null,
      isActive: (json['isActive'] == null) ? true : (json['isActive'] == true),
    );
  }
}

// ==========================================================
// EVENT (indirim veren model)
// ==========================================================

enum DiscountType { percent, amount }

extension DiscountTypeKey on DiscountType {
  String get key => switch (this) {
    DiscountType.percent => 'percent',
    DiscountType.amount => 'amount',
  };
}

DiscountType discountTypeFromString(String s) {
  switch (s) {
    case 'amount':
      return DiscountType.amount;
    case 'percent':
    default:
      return DiscountType.percent;
  }
}

/// Basit ama güçlü zamanlama modeli:
/// - one-time: startAt/endAt
/// - recurring: daysOfWeek + startTime/endTime
enum EventScheduleType { oneTime, recurring }

extension EventScheduleTypeKey on EventScheduleType {
  String get key => switch (this) {
    EventScheduleType.oneTime => 'one_time',
    EventScheduleType.recurring => 'recurring',
  };
}

EventScheduleType eventScheduleTypeFromString(String s) {
  switch (s) {
    case 'recurring':
      return EventScheduleType.recurring;
    case 'one_time':
    default:
      return EventScheduleType.oneTime;
  }
}

/// Gün: 1=Mon ... 7=Sun (backend için stabil)
class EventSchedule {
  final EventScheduleType type;

  /// oneTime
  final DateTime? startAt;
  final DateTime? endAt;

  /// recurring
  final List<int> daysOfWeek; // [1..7]
  final String? startTime; // "16:00"
  final String? endTime; // "18:00"

  const EventSchedule.oneTime({
    required DateTime startAt,
    required DateTime endAt,
  })  : type = EventScheduleType.oneTime,
        startAt = startAt,
        endAt = endAt,
        daysOfWeek = const [],
        startTime = null,
        endTime = null;

  const EventSchedule.recurring({
    required List<int> daysOfWeek,
    required String startTime,
    required String endTime,
  })  : type = EventScheduleType.recurring,
        startAt = null,
        endAt = null,
        daysOfWeek = daysOfWeek,
        startTime = startTime,
        endTime = endTime;

  Map<String, dynamic> toJson() => {
    'type': type.key,
    'startAt': startAt?.toIso8601String(),
    'endAt': endAt?.toIso8601String(),
    'daysOfWeek': daysOfWeek,
    'startTime': startTime,
    'endTime': endTime,
  };

  factory EventSchedule.fromJson(Map<String, dynamic> json) {
    final t = eventScheduleTypeFromString((json['type'] ?? 'one_time').toString());
    if (t == EventScheduleType.recurring) {
      final rawDays = (json['daysOfWeek'] as List?) ?? const [];
      final days = rawDays
          .map((e) => (e is num) ? e.toInt() : int.tryParse('$e') ?? 0)
          .where((x) => x >= 1 && x <= 7)
          .toList();

      return EventSchedule.recurring(
        daysOfWeek: days,
        startTime: (json['startTime'] ?? '00:00').toString(),
        endTime: (json['endTime'] ?? '23:59').toString(),
      );
    }

    return EventSchedule.oneTime(
      startAt: DateTime.parse((json['startAt'] ?? DateTime.now().toIso8601String()).toString()),
      endAt: DateTime.parse((json['endAt'] ?? DateTime.now().toIso8601String()).toString()),
    );
  }
}

/// Event = indirim uygular.
/// targets: product + combo referansları.
class EventModel {
  final String id;
  final String businessId;

  final String name;

  final DiscountType discountType;
  final double value; // percent: 0..100, amount: currency

  final EventSchedule schedule;

  final List<PromotionTargetRef> targets;

  final bool isActive;

  const EventModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.discountType,
    required this.value,
    required this.schedule,
    this.targets = const [],
    this.isActive = true,
  });

  EventModel copyWith({
    String? name,
    DiscountType? discountType,
    double? value,
    EventSchedule? schedule,
    List<PromotionTargetRef>? targets,
    bool? isActive,
  }) {
    return EventModel(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      discountType: discountType ?? this.discountType,
      value: value ?? this.value,
      schedule: schedule ?? this.schedule,
      targets: targets ?? this.targets,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'businessId': businessId,
    'name': name,
    'discountType': discountType.key,
    'value': value,
    'schedule': schedule.toJson(),
    'targets': targets.map((e) => e.toJson()).toList(),
    'isActive': isActive,
  };

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final rawTargets = (json['targets'] as List?) ?? const [];
    final targets = rawTargets
        .whereType<Map>()
        .map((e) => PromotionTargetRef.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return EventModel(
      id: (json['id'] ?? '').toString(),
      businessId: (json['businessId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      discountType: discountTypeFromString((json['discountType'] ?? 'percent').toString()),
      value: (json['value'] is num) ? (json['value'] as num).toDouble() : 0.0,
      schedule: EventSchedule.fromJson(Map<String, dynamic>.from(json['schedule'] ?? const {})),
      targets: targets,
      isActive: (json['isActive'] == null) ? true : (json['isActive'] == true),
    );
  }
}
// ==========================================================
// DRAFT MODELLER (UI tarafında geçici)
// ==========================================================
class ComboItemDraft {
  final String productId;
  final String name;
  final double unitPrice;
  final int qty;

  const ComboItemDraft({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.qty,
  });

  ComboItemDraft copyWith({int? qty}) => ComboItemDraft(
    productId: productId,
    name: name,
    unitPrice: unitPrice,
    qty: qty ?? this.qty,
  );

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'qty': qty,
    'unit_price': unitPrice,
    'name': name, // draft içinde adı tutuyoruz (UI kolaylığı)
  };

  factory ComboItemDraft.fromJson(Map<String, dynamic> json) {
    return ComboItemDraft(
      productId: (json['product_id'] ?? '').toString(),
      qty: (json['qty'] is num) ? (json['qty'] as num).toInt() : 1,
      unitPrice: (json['unit_price'] is num) ? (json['unit_price'] as num).toDouble() : 0.0,
      name: (json['name'] ?? '').toString(),
    );
  }
}

enum ComboPriceMode { auto, fixed }

class ComboDraft {
  final String id; // tmp_... (UI geçici)
  final String name;
  final String? note;

  final ComboPriceMode priceMode; // auto / fixed
  final double? fixedPrice;

  final List<ComboItemDraft> items;

  const ComboDraft({
    required this.id,
    required this.name,
    this.note,
    required this.priceMode,
    this.fixedPrice,
    required this.items,
  });

  ComboDraft copyWith({
    String? id,
    String? name,
    String? note,
    ComboPriceMode? priceMode,
    double? fixedPrice,
    bool setFixedPrice = false, // null yazabilmek için
    List<ComboItemDraft>? items,
  }) {
    return ComboDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      note: note ?? this.note,
      priceMode: priceMode ?? this.priceMode,
      fixedPrice: setFixedPrice ? fixedPrice : (fixedPrice ?? this.fixedPrice),
      items: items ?? this.items,
    );
  }

  double get autoPrice => items.fold<double>(0, (a, x) => a + (x.unitPrice * x.qty));

  double get finalPrice => priceMode == ComboPriceMode.fixed ? (fixedPrice ?? autoPrice) : autoPrice;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'note': note,
    'price_mode': priceMode.name, // 'auto' | 'fixed'
    'fixed_price': fixedPrice,
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory ComboDraft.fromJson(Map<String, dynamic> json) {
    final pm = (json['price_mode'] ?? 'auto').toString();

    return ComboDraft(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      note: json['note']?.toString(),
      priceMode: ComboPriceMode.values.firstWhere(
            (e) => e.name == pm,
        orElse: () => ComboPriceMode.auto,
      ),
      fixedPrice: (json['fixed_price'] is num) ? (json['fixed_price'] as num).toDouble() : null,
      items: (json['items'] as List? ?? [])
          .whereType<Map>()
          .map((e) => ComboItemDraft.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class WeeklyRuleDraft {
  final Set<int> days; // 1..7 (Mon..Sun)
  final TimeOfDay start;
  final TimeOfDay end;

  const WeeklyRuleDraft({
    required this.days,
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toJson() => {
    'days': days.toList(), // Set -> List
    'start_hour': start.hour,
    'start_minute': start.minute,
    'end_hour': end.hour,
    'end_minute': end.minute,
  };

  factory WeeklyRuleDraft.fromJson(Map<String, dynamic> json) {
    return WeeklyRuleDraft(
      days: (json['days'] as List? ?? []).map((e) => (e as num).toInt()).toSet(),
      start: TimeOfDay(
        hour: (json['start_hour'] as num?)?.toInt() ?? 0,
        minute: (json['start_minute'] as num?)?.toInt() ?? 0,
      ),
      end: TimeOfDay(
        hour: (json['end_hour'] as num?)?.toInt() ?? 0,
        minute: (json['end_minute'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}

class EventDraft {
  final String id; // tmp_... (UI geçici)
  final String name;

  final double discountPercent; // 0..100
  final EventScheduleType scheduleType;

  // one-time
  final DateTime? startsAt;
  final DateTime? endsAt;

  // weekly
  final WeeklyRuleDraft? weekly;

  // targets (MVP: sadece ürün)
  final List<String> productIds;

  const EventDraft({
    required this.id,
    required this.name,
    required this.discountPercent,
    required this.scheduleType,
    required this.productIds,
    this.startsAt,
    this.endsAt,
    this.weekly,
  });

  EventDraft copyWith({
    String? id,
    String? name,
    double? discountPercent,
    EventScheduleType? scheduleType,
    List<String>? productIds,
    DateTime? startsAt,
    bool setStartsAt = false,
    DateTime? endsAt,
    bool setEndsAt = false,
    WeeklyRuleDraft? weekly,
    bool setWeekly = false,
  }) {
    return EventDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      discountPercent: discountPercent ?? this.discountPercent,
      scheduleType: scheduleType ?? this.scheduleType,
      productIds: productIds ?? this.productIds,
      startsAt: setStartsAt ? startsAt : (startsAt ?? this.startsAt),
      endsAt: setEndsAt ? endsAt : (endsAt ?? this.endsAt),
      weekly: setWeekly ? weekly : (weekly ?? this.weekly),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'discount_percent': discountPercent,
    'schedule_type': scheduleType.name, // 'oneTime' | 'recurring'
    'product_ids': productIds,
    'starts_at': startsAt?.toIso8601String(),
    'ends_at': endsAt?.toIso8601String(),
    'weekly': weekly?.toJson(),
  };

  factory EventDraft.fromJson(Map<String, dynamic> json) {
    final st = (json['schedule_type'] ?? 'oneTime').toString();

    DateTime? _dt(String key) {
      final v = json[key];
      if (v == null) return null;
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return EventDraft(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      discountPercent: (json['discount_percent'] is num) ? (json['discount_percent'] as num).toDouble() : 0.0,
      scheduleType: EventScheduleType.values.firstWhere(
            (e) => e.name == st,
        orElse: () => EventScheduleType.oneTime,
      ),
      productIds: (json['product_ids'] as List? ?? []).map((e) => e.toString()).toList(),
      startsAt: _dt('starts_at'),
      endsAt: _dt('ends_at'),
      weekly: (json['weekly'] is Map) ? WeeklyRuleDraft.fromJson(Map<String, dynamic>.from(json['weekly'] as Map)) : null,
    );
  }
}

// ==========================================================
// UI Yardımcı Model
// ==========================================================
class IngredientPickResult {
  final double amount;
  final IngredientUnit unit;

  const IngredientPickResult({required this.amount, required this.unit});
}

enum ChoiceType { single, multi }

extension ChoiceTypeLabel on ChoiceType {
  String get label => this == ChoiceType.single ? 'Tek seçim' : 'Çoklu seçim';
}

