// lib/features/panel/profile/create_profile_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/sessions/app_session.dart';
import '../../../app/theme/appetite_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/gradient_button.dart';
import '../../../services/app_service.dart';
import '../../../services/user_service.dart';
import 'create_profile_viewmodel.dart';

class CreateProfileView extends StatefulWidget {
  const CreateProfileView({super.key});

  @override
  State<CreateProfileView> createState() => _CreateProfileViewState();
}

class _CreateProfileViewState extends State<CreateProfileView> {
  late final CreateProfileViewModel vm;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    final services = context.read<AppServices>();
    final session = context.read<AppSession>();

    final UserService userService = services.user;
    vm = CreateProfileViewModel(userService, session);

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
    final s = vm.state;
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Theme(
      data: AppetiteTheme.light(),
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: AppetiteTheme.background(context),
            ),

            Container(
              decoration: AppetiteTheme.background2(context),
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

                        const Text(
                          'Profilini Oluştur',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Bu hesap MVP’de otomatik olarak owner olarak devam eder.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: tokens.muted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Error banner (Login ile aynı pattern)
                        if (s.error != null) ...[
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
                                Icon(Icons.error_outline, color: tokens.danger),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    s.error!,
                                    style: TextStyle(
                                      color: tokens.text,
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
                                'Bilgilerini Gir',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Bu bilgiler işletme sahibinin profilini oluşturur.',
                                style: TextStyle(
                                  color: tokens.muted,
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
                                      label: 'İsim',
                                      hint: 'Adın',
                                      controller: vm.firstNameController,
                                      validator: (v) => vm.validateFirstName(),
                                    ),
                                    const SizedBox(height: 12),
                                    AppTextField(
                                      label: 'Soyisim',
                                      hint: 'Soyadın',
                                      controller: vm.lastNameController,
                                      validator: (v) => vm.validateLastName(),
                                    ),
                                    const SizedBox(height: 14),

                                    GradientButton(
                                      text: s.isLoading ? 'Kaydediliyor...' : 'Devam Et',
                                      isLoading: s.isLoading,
                                      onPressed: s.isLoading ? null : () => _onSubmitPressed(context),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          '© İz • Panel',
                          style: TextStyle(
                            color: tokens.muted.withValues(alpha: 0.85),
                            fontSize: 12,
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
      ),
    );
  }

  Future<void> _onSubmitPressed(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await vm.submit();
    if (!context.mounted) return;

    if (ok) {
      Navigator.pushReplacementNamed(context, AppRoutes.businessCreate);
    }
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  const GradientButton({
    super.key,
    required this.text,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Opacity(
      opacity: disabled ? 0.55 : 1.0,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(tokens.rMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(tokens.rMd),
          onTap: onPressed,
          child: Ink(
            height: 48,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: tokens.appetiteGradient(),
              borderRadius: BorderRadius.circular(tokens.rMd),
              boxShadow: tokens.shadow2,
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
