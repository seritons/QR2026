// lib/app/sessions/app_session.dart
import 'package:flutter/foundation.dart';

import 'user_session.dart';
import 'business_session.dart';
import 'menu_session.dart';
import 'analytics_session.dart';
import 'order_session.dart';

class AppSession extends ChangeNotifier {
  final UserSession user = UserSession();
  final BusinessSession business = BusinessSession();
  final MenuSession menu = MenuSession();

  final AnalyticsSession analytics = AnalyticsSession();
  final OrderSession orders = OrderSession();

  AppSession() {
    user.addListener(_bubble);
    business.addListener(_bubble);
    menu.addListener(_bubble);
    analytics.addListener(_bubble);
    orders.addListener(_bubble);
  }

  void _bubble() => notifyListeners();

  @override
  void dispose() {
    user.removeListener(_bubble);
    business.removeListener(_bubble);
    menu.removeListener(_bubble);
    analytics.removeListener(_bubble);
    orders.removeListener(_bubble);
    super.dispose();
  }

  void clearAll() {
    user.clear();
    business.clear();
    menu.clear();
    analytics.clear();
    orders.clear();
  }
}
