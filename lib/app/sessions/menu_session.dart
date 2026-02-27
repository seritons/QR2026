// lib/app/sessions/menu_session_store.dart
import 'package:flutter/foundation.dart';
import '../../features/panel/menu/menu_models.dart';

class MenuSession extends ChangeNotifier {
  List<MenuModel> _menusLight = const [];
  List<MenuModel> get menusLight => _menusLight;

  MenuModel? _activeMenuFull;
  MenuModel? get activeMenuFull => _activeMenuFull;

  String? _activeMenuId;
  String? get activeMenuId => _activeMenuId;

  void setMenusLight(List<MenuModel> v) {
    _menusLight = v;
    notifyListeners();
  }

  void setActiveMenuFull({required String menuId, required MenuModel menu}) {
    _activeMenuId = menuId;
    _activeMenuFull = menu;
    notifyListeners();
  }

  void clear() {
    _menusLight = const [];
    _activeMenuFull = null;
    _activeMenuId = null;
    notifyListeners();
  }
}
