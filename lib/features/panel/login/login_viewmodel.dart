import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../../services/boot_service.dart';

import '../../../app/sessions/app_session.dart';
import '../../../app/models/user_model.dart';
import '../../../app/models/business_card.dart';
import '../../../app/models/business_model.dart';
import '../menu/menu_models.dart';

class LoginState {
  final bool isLoading;
  final String? error;

  const LoginState({this.isLoading = false, this.error});

  LoginState copyWith({bool? isLoading, String? error}) =>
      LoginState(isLoading: isLoading ?? this.isLoading, error: error);
}

/// Yeni akış için next step
enum BootNextStep { createProfile, createBusiness, pickBusiness, enterDashboard }

BootNextStep bootNextStepFromString(String raw) {
  final s = raw.trim();

  // DB'den "createProfile" / "createBusiness" / "pickBusiness" / "enterDashboard" geliyor
  switch (s) {
    case 'createProfile':
      return BootNextStep.createProfile;
    case 'createBusiness':
      return BootNextStep.createBusiness;
    case 'pickBusiness':
      return BootNextStep.pickBusiness;
    case 'enterDashboard':
    default:
      return BootNextStep.enterDashboard;
  }
}

class LoginViewModel extends ChangeNotifier {
  final AuthService _auth;
  final BootService _boot;
  final AppSession _session;

  LoginState state = const LoginState();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  LoginViewModel(this._auth, this._boot, this._session);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String _prettyJson(dynamic v) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(v);
    } catch (_) {
      return v.toString();
    }
  }

  void _logBig(String tag, dynamic v) {
    if (!kDebugMode) return;
    final s = _prettyJson(v);

    // debugPrint uzun metni kesebilir -> chunk
    const chunkSize = 900;
    debugPrint('[LoginVM] $tag (len=${s.length})');
    for (var i = 0; i < s.length; i += chunkSize) {
      final end = (i + chunkSize < s.length) ? i + chunkSize : s.length;
      debugPrint(s.substring(i, end));
    }
  }

  Future<BootNextStep?> signInAndBootstrap() async {
    void log(String msg) {
      if (kDebugMode) debugPrint('[LoginVM] $msg');
    }

    final sw = Stopwatch()..start();

    state = state.copyWith(isLoading: true, error: null);
    notifyListeners();

    final email = emailController.text.trim();
    final passLen = passwordController.text.length;

    log('START signInAndBootstrap()');
    log('Input email="$email" passLen=$passLen');
    log('UI state: isLoading=${state.isLoading}');

    try {
      // -------------------------
      // STEP 1: AUTH
      // -------------------------
      log('STEP 1 -> auth.signInWithEmailPassword()');
      final swAuth = Stopwatch()..start();

      await _auth.signInWithEmailPassword(
        email: email,
        password: passwordController.text,
      );

      swAuth.stop();
      log('STEP 1 OK (${swAuth.elapsedMilliseconds}ms)');

      final uid = _auth.currentUidOrNull();
      log('Auth snapshot: uid=${uid ?? "NULL"}');
      if (uid == null) throw Exception('Oturum açılamadı (uid null)');

      // -------------------------
      // STEP 2: BOOT RPC
      // -------------------------
      log('STEP 2 -> boot.loginBoot()');
      final swBoot = Stopwatch()..start();

      final bootJson = await _boot.loginBoot();

      swBoot.stop();
      log('STEP 2 OK (${swBoot.elapsedMilliseconds}ms)');
      log('boot keys=${bootJson.keys.toList()}');

      // ✅ FULL BOOT JSON (debug)
      _logBig('BOOT JSON', bootJson);

      final ok = bootJson['ok'] == true;
      if (!ok) {
        final reason = (bootJson['reason'] ?? 'boot_failed').toString();
        throw Exception('Boot başarısız: $reason');
      }

      final nextRaw = (bootJson['next'] ?? 'enterDashboard').toString();
      final next = bootNextStepFromString(nextRaw);
      log('Next step raw="$nextRaw" parsed=$next');

      // -------------------------
      // STEP 3: MAP + SET SESSIONS
      // -------------------------

      // --- USER ---
      final userMap = (bootJson['user'] as Map?)?.cast<String, dynamic>();
      if (userMap == null) throw Exception('Boot user missing');

      final relationRaw = (userMap['relationBusiness'] ?? 'staff').toString();

      final user = UserModel.fromJson({
        'id': userMap['id'],
        'firstName': userMap['firstName'],
        'lastName': userMap['lastName'],
        'email': userMap['email'],
        'relationBusiness': relationRaw,
      });

      _session.user.setUser(user);
      log('Session user set: ${user.id} ${user.firstName} role=$relationRaw');

      // --- MENU (boot payload -> MenuSession) ---
      // beklenen shape:
      //  bootJson['menus'] = [{id,name}, ...]
      //  bootJson['activeMenuId'] = "uuid" (optional)
      //  bootJson['activeMenu'] = full menu json (optional)
      try {
        final rawMenus = bootJson['menus'];
        final menusList = (rawMenus is List) ? rawMenus : const <dynamic>[];

        final menusLight = <MenuModel>[];
        for (final e in menusList) {
          if (e is Map) {
            final m = Map<String, dynamic>.from(e);
            menusLight.add(
              MenuModel(
                id: (m['id'] ?? '').toString(),
                name: (m['name'] ?? '').toString(),
                businessId: (m['business_id'] ?? '').toString(),
                categories: const [],
              ),
            );
          }
        }

        _session.menu.setMenusLight(menusLight);

        final activeMenuId = (bootJson['activeMenuId'] as String?)?.trim();
        final activeMenuRaw = bootJson['activeMenu'];

        log('BOOT menusLight count=${menusLight.length}');
        log('BOOT activeMenuId=${activeMenuId ?? "NULL"} activeMenuType=${activeMenuRaw?.runtimeType}');

        if (activeMenuId != null &&
            activeMenuId.isNotEmpty &&
            activeMenuRaw is Map) {
          final full = MenuModel.fromJson(
            Map<String, dynamic>.from(activeMenuRaw),
          );
          _session.menu.setActiveMenuFull(menuId: activeMenuId, menu: full);
          log('Session menu active set: id=$activeMenuId cats=${full.categories.length}');
        } else {
          // aktif menü yoksa sorun değil: sadece light list kalır
          log('Session menu active NOT set (no activeMenuId/activeMenu)');
        }
      } catch (e, st) {
        // boot menü parse patlarsa login'i düşürmeyelim, sadece menüyü boşla
        log('MENU BOOT PARSE ERROR=$e');
        if (kDebugMode) debugPrint(st.toString());
        _session.menu.clear();
      }

      // --- BUSINESS ---
      if (next == BootNextStep.pickBusiness) {
        final rel = (bootJson['relationBusiness'] as Map?)?.cast<String, dynamic>();
        final items = (rel?['items'] as List?) ?? const [];

        final cards = items.map((e) {
          final m = (e as Map).cast<String, dynamic>();
          final biz = (m['business'] as Map).cast<String, dynamic>();
          return BusinessCard.fromSupabase(biz);
        }).toList();

        _session.business.setBusinessCards(cards);
        log('Session businessCards set: count=${cards.length}');
      } else if (next == BootNextStep.enterDashboard) {
        final bizMap = (bootJson['business'] as Map?)?.cast<String, dynamic>();
        if (bizMap == null) throw Exception('Boot business missing (single)');

        final business = BusinessModel.fromJson(bizMap);
        _session.business.setBusiness(business);
        log('Session business set: id=${business.id} name=${business.name}');
      } else {
        _session.business.clear();
        _session.menu.clear(); // ✅ createProfile/createBusiness’te menü de boş
        log('Session business/menu cleared (next=$next)');
      }

      state = state.copyWith(isLoading: false, error: null);
      notifyListeners();

      sw.stop();
      log('DONE success (${sw.elapsedMilliseconds}ms)');
      return next;
    } catch (e, st) {
      sw.stop();
      log('ERROR (${sw.elapsedMilliseconds}ms): $e');
      if (kDebugMode) debugPrint(st.toString());

      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      notifyListeners();
      return null;
    }
  }

}
