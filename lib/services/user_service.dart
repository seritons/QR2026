// lib/services/user_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/models/user_model.dart';

class UserService {
  final SupabaseClient _sb;
  UserService(this._sb);

  void _log(String msg) => debugPrint('[UserService] $msg');

  // =========================================================
  // CREATE PROFILE (RPC)
  // RPC: public.create_business_user_profile(p_first_name text, p_last_name text)
  // returns: { ok: true, user: {...} }
  // =========================================================
  Future<UserModel> createProfile({
    required String firstName,
    required String lastName,
  }) async {
    final f = firstName.trim();
    final l = lastName.trim();

    if (f.length < 2) throw Exception('İsim en az 2 karakter olmalı.');
    if (l.length < 2) throw Exception('Soyisim en az 2 karakter olmalı.');

    _log('createProfile START first="$f" last="$l"');

    final res = await _sb.rpc(
      'create_business_user_profile',
      params: {
        'p_first_name': f,
        'p_last_name': l,
      },
    );

    if (res == null || res is! Map) {
      _log('createProfile FAIL invalid RPC response type=${res.runtimeType}');
      throw Exception('Profil oluşturulamadı (RPC yanıtı geçersiz).');
    }

    final map = (res as Map).cast<String, dynamic>();
    final ok = map['ok'] == true;
    if (!ok) {
      final reason = (map['reason'] ?? 'profile_failed').toString();
      _log('createProfile FAIL ok=false reason=$reason');
      throw Exception('Profil oluşturulamadı: $reason');
    }

    final userMap = (map['user'] as Map?)?.cast<String, dynamic>();
    if (userMap == null) {
      _log('createProfile FAIL user missing');
      throw Exception('Profil oluşturulamadı (user missing).');
    }

    // relationBusiness kesin owner (MVP)
    final user = UserModel.fromJson({
      'id': userMap['id'],
      'firstName': userMap['firstName'],
      'lastName': userMap['lastName'],
      'email': userMap['email'],
      'relationBusiness': 'owner',
    });

    _log('createProfile DONE userId=${user.id} email=${user.email}');
    return user;
  }

  // =========================================================
  // GET MY PROFILE (placeholder)
  // Öneri: RPC yaz -> get_my_profile()
  // =========================================================
  Future<UserModel> getMyProfile() async {
    _log('getMyProfile TODO');
    throw UnimplementedError('getMyProfile RPC henüz yazılmadı.');
  }

  // =========================================================
  // UPDATE PROFILE (placeholder)
  // Öneri: RPC yaz -> update_business_user_profile(p_first_name, p_last_name)
  // =========================================================
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
  }) async {
    _log('updateProfile TODO first=$firstName last=$lastName');
    throw UnimplementedError('updateProfile RPC henüz yazılmadı.');
  }

  // =========================================================
  // DELETE PROFILE (placeholder)
  // DİKKAT: auth.users silme client ile yapılamaz (admin gerekli).
  // Burada ancak app profile satırını silebilirsin.
  // Öneri: RPC yaz -> delete_business_user_profile()
  // =========================================================
  Future<void> deleteMyProfile() async {
    _log('deleteMyProfile TODO');
    throw UnimplementedError('deleteMyProfile RPC henüz yazılmadı.');
  }

  // =========================================================
  // HELPERS
  // =========================================================
  String? currentUidOrNull() => _sb.auth.currentUser?.id;
}
