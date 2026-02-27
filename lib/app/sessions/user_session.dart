import 'package:flutter/cupertino.dart';
import 'package:qrpanel/app/models/user_model.dart';

class UserSession extends ChangeNotifier {
  UserModel? _user;

  UserSession({UserModel? user}) : _user = user;

  UserModel? get user => _user;

  bool get isAuthenticated => _user != null;
  String? get userId => _user?.id;
  UserRelationBusiness? get role => _user?.relationBusiness;

  String? get fullName =>
      _user == null ? null : '${_user!.firstName} ${_user!.lastName}'.trim();

  void setUser(UserModel? user) {
    _user = user;
    notifyListeners();
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
}
