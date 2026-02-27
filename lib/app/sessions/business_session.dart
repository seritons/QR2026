import 'package:flutter/foundation.dart';

import 'package:qrpanel/app/models/business_model.dart';
import '../models/business_card.dart';

class BusinessSession extends ChangeNotifier {
  BusinessModel? _business;
  List<BusinessCard> _businessCards;

  BusinessModel? get business => _business;
  List<BusinessCard> get businessCards => List.unmodifiable(_businessCards);

  BusinessSession({
    BusinessModel? business,
    List<BusinessCard> businessCards = const [],
  })  : _business = business,
        _businessCards = List<BusinessCard>.from(businessCards);

  /// Tek işletme aktif mi?
  bool get hasActiveBusiness => _business != null;

  /// Çoklu işletme seçimi gerekiyor mu?
  bool get requiresSelection => _business == null && _businessCards.isNotEmpty;

  /// Hiç işletme yok mu?
  bool get hasNoBusiness => _business == null && _businessCards.isEmpty;

  /// Aktif business id
  String? get activeBusinessId => _business?.id;

  /// Çoklu işletmeden seçim sonrası (detaylı business geldiğinde)
  void setBusiness(BusinessModel business) {
    _business = business;
    _businessCards = <BusinessCard>[];
    notifyListeners();
  }

  /// Boot'ta çoklu işletme varsa kartları set et
  void setBusinessCards(List<BusinessCard> cards) {
    _businessCards = List<BusinessCard>.from(cards);
    _business = null;
    notifyListeners();
  }

  /// İstersen: kart listesinden seçilen id'yi bul (detay çekmeden önce UI için)
  BusinessCard? findCard(String businessId) {
    final id = businessId.trim();
    for (final c in _businessCards) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Logout / reset
  void clear() {
    _business = null;
    _businessCards = <BusinessCard>[];
    notifyListeners();
  }
}
