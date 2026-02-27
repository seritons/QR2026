import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import 'models.dart';

class RegisterViewModel extends ChangeNotifier {
  final AuthService _auth;
  RegisterViewModel(this._auth);

  RegisterState state = const RegisterState();

  final adminEmail = TextEditingController();
  final adminPassword = TextEditingController();
  final adminPassword2 = TextEditingController();

  @override
  void dispose() {
    adminEmail.dispose();
    adminPassword.dispose();
    adminPassword2.dispose();
    super.dispose();
  }

  void _setLoading(bool v) {
    state = state.copyWith(isLoading: v, error: null);
    notifyListeners();
  }

  void _setError(Object e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString().replaceFirst('Exception: ', ''),
    );
    notifyListeners();
  }

  Future<void> submitAdminAuth() async {
    _setLoading(true);
    try {
      final email = adminEmail.text.trim();
      final p1 = adminPassword.text;
      final p2 = adminPassword2.text;

      if (!email.contains('@')) throw Exception('Geçerli e-posta gir');
      if (p1.length < 6) throw Exception('Şifre en az 6 karakter');
      if (p1 != p2) throw Exception('Şifreler eşleşmiyor');

      // ✅ sadece signUp: session beklemiyoruz
      await _auth.signUpWithEmailPassword(email: email, password: p1);

      state = state.copyWith(isLoading: false, step: RegisterStep.done, error: null);
      notifyListeners();
    } catch (e) {
      _setError(e);
    }
  }
}
