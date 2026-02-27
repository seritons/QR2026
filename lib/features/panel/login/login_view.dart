import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:qrpanel/services/business_service.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/sessions/app_session.dart';
import '../../../app/theme/appetite_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/gradient_button.dart';
import '../../../services/app_service.dart';
import '../../../services/auth_service.dart';
import 'login_viewmodel.dart';

class PanelLoginView extends StatefulWidget {
  const PanelLoginView({super.key});

  @override
  State<PanelLoginView> createState() => _PanelLoginViewState();
}

class _PanelLoginViewState extends State<PanelLoginView> {
  late final LoginViewModel vm;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // initState içinde context.read kullanılabilir
    final services = context.read<AppServices>();
    final session = context.read<AppSession>();

    // LoginVM constructor: (AuthService, BootService, AppSession)
    vm = LoginViewModel(services.auth, services.boot, session);

    vm.addListener(_onVmChanged);
  }

  void _onVmChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final banner = (args is Map) ? args['banner'] as String? : null;

    return Theme(
      data: AppetiteTheme.light(),
      child: Scaffold(
        body: Stack(
          children: [
            Container(decoration: AppetiteTheme.background()),
            Container(decoration: AppetiteTheme.background2()),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 6),

                          // Logo
                          Container(
                            child: Image.asset(
                              'assets/images/iz_logo.png',
                              height: 134,
                            ),
                          ),


                          const SizedBox(height: 5),

                          const Text(
                            '    •\nPanel',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'İşletmeni yönet, siparişleri takip et, analitiği gör.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTokens.muted,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Banner (Register -> Login mesajı)
                          if (banner != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTokens.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTokens.primary.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                banner,
                                style: TextStyle(
                                  color: AppTokens.text,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Error
                          if (vm.state.error != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTokens.danger.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTokens.danger.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.error_outline, color: AppTokens.danger),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      vm.state.error!,
                                      style: TextStyle(
                                        color: AppTokens.text,
                                        fontWeight: FontWeight.w700,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Giriş Yap',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Hesabınla giriş yap.',
                                  style: TextStyle(
                                    color: AppTokens.muted,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      AppTextField(
                                        label: 'E-posta',
                                        hint: 'ornek@isletme.com',
                                        controller: vm.emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (v) {
                                          final s = (v ?? '').trim();
                                          if (s.isEmpty) return 'E-posta gerekli';
                                          if (!s.contains('@')) return 'Geçerli e-posta gir';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      AppTextField(
                                        label: 'Şifre',
                                        hint: '••••••••',
                                        controller: vm.passwordController,
                                        obscureText: true,
                                        validator: (v) {
                                          final s = (v ?? '');
                                          if (s.isEmpty) return 'Şifre gerekli';
                                          if (s.length < 6) return 'En az 6 karakter';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 14),

                                      GradientButton(
                                        text: vm.state.isLoading ? 'Giriş yapılıyor...' : 'Giriş Yap',
                                        isLoading: vm.state.isLoading,
                                        onPressed: vm.state.isLoading
                                            ? null
                                            : () async {
                                          if (!(_formKey.currentState?.validate() ?? false)) return;

                                          final next = await vm.signInAndBootstrap();
                                          if (!context.mounted || next == null) return;
                                          debugPrint('businessCreate=${AppRoutes.businessCreate}');

                                          switch (next) {
                                            case BootNextStep.createProfile:
                                              Navigator.pushReplacementNamed(context, AppRoutes.createProfile);
                                              break;

                                            case BootNextStep.createBusiness:
                                              Navigator.pushReplacementNamed(context, AppRoutes.businessCreate);
                                              break;
                                            case BootNextStep.pickBusiness:
                                              Navigator.pushReplacementNamed(context, AppRoutes.businessSelect);
                                              break;
                                            case BootNextStep.enterDashboard:
                                              Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
                                              break;

                                          }
                                        },
                                      ),

                                      const SizedBox(height: 12),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Hesabın yok mu?',
                                            style: TextStyle(color: AppTokens.muted, fontSize: 13),
                                          ),
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.pushNamed(context, '/panel/register');
                                            },
                                            child: Text(
                                              'Kayıt Ol',
                                              style: TextStyle(
                                                color: AppTokens.primary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          Text(
                            '© İz • Panel',
                            style: TextStyle(
                              color: AppTokens.muted.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
