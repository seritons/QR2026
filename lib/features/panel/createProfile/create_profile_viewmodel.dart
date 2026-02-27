// lib/features/panel/profile/create_profile_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qrpanel/services/user_service.dart';
import '../../../app/sessions/app_session.dart';

class CreateProfileState {
  final bool isLoading;
  final String? error;

  const CreateProfileState({this.isLoading = false, this.error});

  CreateProfileState copyWith({bool? isLoading, String? error, bool setError = false}) {
    return CreateProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: setError ? error : this.error,
    );
  }
}

class CreateProfileViewModel extends ChangeNotifier {
  final UserService _userService;
  final AppSession _session;

  CreateProfileState state = const CreateProfileState();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  CreateProfileViewModel(this._userService, this._session);

  void _log(String msg) {
    if (kDebugMode) debugPrint('[CreateProfileVM] $msg');
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  String? validateFirstName() {
    final v = firstNameController.text.trim();

    if (v.isEmpty) return 'İsim gerekli';
    if (v.length < 2) return 'İsim çok kısa';
    if (v.length > 40) return 'İsim çok uzun';

    return null;
  }

  String? validateLastName() {
    final v = lastNameController.text.trim();

    if (v.isEmpty) return 'Soyisim gerekli';
    if (v.length < 2) return 'Soyisim çok kısa';
    if (v.length > 40) return 'Soyisim çok uzun';

    return null;
  }

  bool validate() {
    final f = firstNameController.text.trim();
    final l = lastNameController.text.trim();

    if (f.length < 2) {
      state = state.copyWith(setError: true, error: 'İsim en az 2 karakter olmalı.');
      notifyListeners();
      return false;
    }
    if (l.length < 2) {
      state = state.copyWith(setError: true, error: 'Soyisim en az 2 karakter olmalı.');
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> submit() async {
    if (state.isLoading) return false;
    if (!validate()) return false;

    state = state.copyWith(isLoading: true, setError: true, error: null);
    notifyListeners();

    try {
      final f = firstNameController.text.trim();
      final l = lastNameController.text.trim();

      _log('createProfile START first="$f" last="$l"');

      // ✅ Direkt UserModel dönüyor
      final user = await _userService.createProfile(
        firstName: f,
        lastName: l,
      );

      // relationBusiness zaten owner olarak set ediliyor
      _session.user.setUser(user);

      _log('UserSession updated userId=${user.id} role=${user.relationBusiness.name}');

      state = state.copyWith(isLoading: false, setError: true, error: null);
      notifyListeners();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        setError: true,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      notifyListeners();
      return false;
    }
  }

}
