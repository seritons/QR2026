import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {

  final SupabaseClient _client;
  AuthService(this._client);

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (!email.contains('@')) throw Exception('Geçerli bir e-posta gir.');
    if (password.length < 6) throw Exception('Şifre en az 6 karakter olmalı.');

    await _client.auth.signInWithPassword(email: email, password: password);

    if (_client.auth.currentSession == null) {
      throw Exception('Giriş başarısız. Bilgileri kontrol et.');
    }
  }

  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (!email.contains('@')) throw Exception('Geçerli bir e-posta gir.');
    if (password.length < 6) throw Exception('Şifre en az 6 karakter olmalı.');

    // Email confirmation açıksa session beklemiyoruz.
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
  String? currentUidOrNull() {
    // Supabase client erişimine göre uyarlayacaksın
    // örn: return _client.auth.currentUser?.id;
    return _client.auth.currentUser?.id; // placeholder
  }

}
