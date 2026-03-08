import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/sessions/app_session.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/appetite_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/gradient_button.dart';
import '../../../services/app_service.dart';
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

    final services = context.read<AppServices>();
    final session = context.read<AppSession>();

    vm = LoginViewModel(services.auth, services.boot, session);
    vm.addListener(_onVmChanged);
  }

  void _onVmChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    vm.removeListener(_onVmChanged);
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final banner = (args is Map) ? args['banner'] as String? : null;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: AppetiteTheme.background(context),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: AppetiteTheme.background2(context),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 6),

                      Image.asset(
                        'assets/images/iz_logo.png',
                        height: 134,
                      ),

                      const SizedBox(height: 5),

                      Text(
                        '    •\nPanel',
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineItalic.copyWith(
                          color: tokens.text,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'İşletmeni yönet, siparişleri takip et, analitiği gör.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(
                          color: tokens.muted,
                        ),
                      ),

                      const SizedBox(height: 14),

                      if (banner != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tokens.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: tokens.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            banner,
                            style: AppTypography.bodyStrong.copyWith(
                              color: tokens.text,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      if (vm.state.error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tokens.danger.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: tokens.danger.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: tokens.danger,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  vm.state.error!,
                                  style: AppTypography.bodyStrong.copyWith(
                                    color: tokens.text,
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
                            Text(
                              'Giriş Yap',
                              style: AppTypography.titleItalic.copyWith(
                                color: tokens.text,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hesabınla giriş yap.',
                              style: AppTypography.body.copyWith(
                                color: tokens.muted,
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
                                    text: vm.state.isLoading
                                        ? 'Giriş yapılıyor...'
                                        : 'Giriş Yap',
                                    isLoading: vm.state.isLoading,
                                    onPressed: vm.state.isLoading
                                        ? null
                                        : () async {
                                      if (!(_formKey.currentState?.validate() ?? false)) {
                                        return;
                                      }

                                      final next = await vm.signInAndBootstrap();
                                      if (!context.mounted || next == null) return;

                                      switch (next) {
                                        case BootNextStep.createProfile:
                                          Navigator.pushReplacementNamed(
                                            context,
                                            AppRoutes.createProfile,
                                          );
                                          break;

                                        case BootNextStep.createBusiness:
                                          Navigator.pushReplacementNamed(
                                            context,
                                            AppRoutes.businessCreate,
                                          );
                                          break;

                                        case BootNextStep.pickBusiness:
                                          Navigator.pushReplacementNamed(
                                            context,
                                            AppRoutes.businessSelect,
                                          );
                                          break;

                                        case BootNextStep.enterDashboard:
                                          Navigator.pushReplacementNamed(
                                            context,
                                            AppRoutes.dashboard,
                                          );
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
                                        style: AppTypography.body.copyWith(
                                          color: tokens.muted,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            AppRoutes.register,
                                          );
                                        },
                                        child: Text(
                                          'Kayıt Ol',
                                          style: AppTypography.bodyStrong.copyWith(
                                            color: tokens.primary,
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
                        isDark ? '© İz • Panel • Dark' : '© İz • Panel • Light',
                        style: AppTypography.captionItalic.copyWith(
                          color: tokens.muted.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
