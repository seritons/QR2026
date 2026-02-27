// lib/app/app_services.dart
import 'package:qrpanel/services/boot_service.dart';
import 'package:qrpanel/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/business_service.dart';
import '../services/menu_service.dart';

class AppServices {
  final SupabaseClient sb;

  late final AuthService auth;
  late final BusinessService business;
  late final MenuService menu;
  late final BootService boot;
  late final UserService user;

  AppServices(this.sb) {
    auth = AuthService(sb);
    user = UserService(sb);
    business = BusinessService(sb);
    menu = MenuService(sb);
    boot = BootService(sb);
  }
}
