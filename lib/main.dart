// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qrpanel/features/panel/createProfile/create_profile_view.dart';
import 'package:qrpanel/services/app_service.dart';
import 'package:qrpanel/services/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/routes/app_routes.dart';
import 'app/sessions/app_session.dart';
import 'app/theme/appetite_theme.dart';
import 'features/panel/login/login_view.dart';
import 'features/panel/onboarding/business/business_view.dart';
import 'features/panel/onboarding/business/select/business_select_view.dart';
import 'features/panel/register/register_view.dart';
import 'features/panel/shell/panel_shell_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // senin init’in:
  SupabaseClientProvider.init();

  runApp(const QrPanelApp());
}

class QrPanelApp extends StatelessWidget {
  const QrPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sb = Supabase.instance.client;

    return MultiProvider(
      providers: [
        // 1) Services (stateless)
        Provider<AppServices>(
          create: (_) => AppServices(sb),
        ),

        // 2) AppSession (stateful)
        ChangeNotifierProvider<AppSession>(
          create: (ctx) => AppSession(),
        ),

        // İstersen kısa yol: UserSessionManager’ı doğrudan expose et
        ChangeNotifierProvider(
          create: (ctx) => ctx.read<AppSession>().user,
        ),
      ],
      child: MaterialApp(
        theme: AppetiteTheme.light(),
        darkTheme: AppetiteTheme.dark(),
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (_) => const PanelLoginView(),
          AppRoutes.createProfile: (_) => const CreateProfileView(),
          AppRoutes.register: (_) => const PanelRegisterView(),
          AppRoutes.dashboard: (_) => const PanelShellView(),
          AppRoutes.businessCreate: (_) => const BusinessOnboardingView(),
          AppRoutes.businessSelect: (_) => const BusinessSelectView(),
        },
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route bulunamadı: ${settings.name}')),
          ),
        ),
      ),
    );
  }
}
