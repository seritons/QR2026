import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/appetite_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/gradient_button.dart';
import '../../../services/app_service.dart';
import '../../../services/auth_service.dart';
import 'models.dart';
import 'register_viewmodel.dart';

class PanelRegisterView extends StatefulWidget {
  const PanelRegisterView({super.key});

  @override
  State<PanelRegisterView> createState() => _PanelRegisterViewState();
}

class _PanelRegisterViewState extends State<PanelRegisterView> {
  late final RegisterViewModel vm;
  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    final services = context.read<AppServices>();
    vm = RegisterViewModel(services.auth);
    vm.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
                      child: Column(
                        children: [
                          Image.asset('assets/images/iz_logo.png', height: 56),
                          const SizedBox(height: 10),
                          const Text('Kayıt Ol', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text(
                            'Admin hesabını oluştur. Sonra e-postanı onaylayıp giriş yap.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTokens.muted, fontSize: 13, height: 1.35),
                          ),
                          const SizedBox(height: 14),

                          if (vm.state.error != null) ...[
                            AppCard(
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(vm.state.error!, style: const TextStyle(fontWeight: FontWeight.w700))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (vm.state.step == RegisterStep.adminAuth)
                            AppCard(
                              child: Form(
                                key: _form,
                                child: Column(
                                  children: [
                                    AppTextField(
                                      label: 'E-posta',
                                      hint: 'admin@isletme.com',
                                      controller: vm.adminEmail,
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
                                      controller: vm.adminPassword,
                                      obscureText: true,
                                      validator: (v) => (v ?? '').length < 6 ? 'En az 6 karakter' : null,
                                    ),
                                    const SizedBox(height: 12),
                                    AppTextField(
                                      label: 'Şifre (tekrar)',
                                      hint: '••••••••',
                                      controller: vm.adminPassword2,
                                      obscureText: true,
                                      validator: (v) => (v ?? '') != vm.adminPassword.text ? 'Şifreler eşleşmiyor' : null,
                                    ),
                                    const SizedBox(height: 14),
                                    GradientButton(
                                      text: vm.state.isLoading ? 'Oluşturuluyor...' : 'Hesap Oluştur',
                                      isLoading: vm.state.isLoading,
                                      onPressed: vm.state.isLoading
                                          ? null
                                          : () async {
                                        if (!(_form.currentState?.validate() ?? false)) return;
                                        await vm.submitAdminAuth();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            AppCard(
                              child: Column(
                                children: [
                                  const Icon(Icons.mark_email_read_outlined, size: 38),
                                  const SizedBox(height: 10),
                                  const Text('Kayıt alındı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 6),
                                  Text(
                                    'E-postana doğrulama linki gönderdik.\n'
                                        'Onayladıktan sonra giriş yapabilirsin.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppTokens.muted, fontSize: 13, height: 1.35),
                                  ),
                                  const SizedBox(height: 14),
                                  GradientButton(
                                    text: 'Giriş sayfasına git',
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/panel/login',
                                        arguments: const {
                                          'banner': 'E-postanı onayladıysan şimdi giriş yapabilirsin.',
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(context, '/panel/login'),
                            child: Text(
                              'Zaten hesabın var mı? Giriş Yap',
                              style: TextStyle(color: AppTokens.primary, fontWeight: FontWeight.w900),
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
