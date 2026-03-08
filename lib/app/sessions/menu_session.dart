import 'package:flutter/foundation.dart';
import '../../features/panel/menu/menu_models.dart';

class MenuSession extends ChangeNotifier {
  List<MenuModel> _menusFull = const [];
  List<MenuModel> get menusFull => _menusFull;

  List<MenuModel> _menusLight = const [];
  List<MenuModel> get menusLight => _menusLight;

  MenuModel? _activeMenuFull;
  MenuModel? get activeMenuFull => _activeMenuFull;

  String? _activeMenuId;
  String? get activeMenuId => _activeMenuId;

  bool get hasActiveMenu => _activeMenuFull != null;

  void setMenusFull(List<MenuModel> full, {String? preferActiveMenuId}) {
    _menusFull = full;
    _rebuildLight();

    if (full.isEmpty) {
      _activeMenuId = null;
      _activeMenuFull = null;
      notifyListeners();
      return;
    }

    final preferredId = preferActiveMenuId?.trim();
    final found = (preferredId != null && preferredId.isNotEmpty)
        ? _tryFindMenuById(preferredId)
        : null;

    final picked = found ?? full.first;

    _activeMenuId = picked.id;
    _activeMenuFull = picked;
    notifyListeners();
  }

  void setMenusLight(List<MenuModel> v, {String? preferActiveMenuId}) {
    _menusLight = v;

    if (v.isEmpty) {
      _activeMenuId = null;
      _activeMenuFull = null;
      notifyListeners();
      return;
    }

    if (preferActiveMenuId != null && preferActiveMenuId.trim().isNotEmpty) {
      _activeMenuId = preferActiveMenuId.trim();
    } else {
      _activeMenuId ??= v.first.id;
    }

    notifyListeners();
  }

  void selectActiveMenu(String menuId) {
    final id = menuId.trim();
    if (id.isEmpty) return;

    final found = _tryFindMenuById(id);
    if (found == null) {
      _activeMenuId = id; // light listte seçili olabilir, full henüz yüklenmemiş olabilir
      _activeMenuFull = null;
      notifyListeners();
      return;
    }

    _activeMenuId = found.id;
    _activeMenuFull = found;
    notifyListeners();
  }

  void upsertMenu(MenuModel menu, {bool select = false}) {
    final list = [..._menusFull];
    final idx = list.indexWhere((m) => m.id == menu.id);

    if (idx >= 0) {
      list[idx] = menu;
    } else {
      list.add(menu);
    }

    _menusFull = list;
    _rebuildLight();

    if (select || _activeMenuId == menu.id || _activeMenuFull == null) {
      _activeMenuId = menu.id;
      _activeMenuFull = menu;
    }

    notifyListeners();
  }

  void deleteMenu(String menuId) {
    final id = menuId.trim();
    if (id.isEmpty) return;

    _menusFull = _menusFull.where((m) => m.id != id).toList();
    _rebuildLight();

    if (_activeMenuId == id) {
      if (_menusFull.isEmpty) {
        _activeMenuId = null;
        _activeMenuFull = null;
      } else {
        _activeMenuId = _menusFull.first.id;
        _activeMenuFull = _menusFull.first;
      }
    }

    notifyListeners();
  }

  void updateActiveMenu(MenuModel updated) {
    upsertMenu(updated, select: true);
  }

  void clear() {
    _menusFull = const [];
    _menusLight = const [];
    _activeMenuFull = null;
    _activeMenuId = null;
    notifyListeners();
  }

  void setActiveMenuFull({required String menuId, required MenuModel menu}) {
    _activeMenuId = menuId;
    _activeMenuFull = menu;

    final idx = _menusFull.indexWhere((m) => m.id == menuId);
    if (idx >= 0) {
      _menusFull[idx] = menu;
    } else {
      _menusFull = [..._menusFull, menu];
    }

    _rebuildLight();
    notifyListeners();
  }

  MenuModel? findFullMenuById(String menuId) {
    final id = menuId.trim();
    if (id.isEmpty) return null;
    return _tryFindMenuById(id);
  }

  MenuModel? _tryFindMenuById(String id) {
    for (final m in _menusFull) {
      if (m.id == id) return m;
    }
    return null;
  }

  void _rebuildLight() {
    _menusLight = _menusFull
        .map((m) => MenuModel(
      id: m.id,
      businessId: m.businessId,
      name: m.name,
    ))
        .toList();
  }
}