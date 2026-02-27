import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qrpanel/app/sessions/app_session.dart';
import '../../../../app/theme/appetite_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../app/widgets/app_card.dart';
import '../../../../app/widgets/app_text_field.dart';
import '../../../../app/widgets/gradient_button.dart';
import '../../../../services/app_service.dart';
import 'business_viewmodel.dart';
import 'models.dart';

class BusinessOnboardingView extends StatefulWidget {
  const BusinessOnboardingView({super.key});

  @override
  State<BusinessOnboardingView> createState() => _BusinessOnboardingViewState();
}

class _BusinessOnboardingViewState extends State<BusinessOnboardingView> {
  late final BusinessOnboardingViewModel vm;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    final services = context.read<AppServices>();
    final session = context.read<AppSession>();

    vm = BusinessOnboardingViewModel(services.business,session.business);
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
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                      child: Column(
                        children: [
                          Image.asset('assets/images/iz_logo.png', height: 56),
                          const SizedBox(height: 10),
                          Text(
                            vm.state.step == BusinessStep.core ? 'İşletme Bilgileri' : 'Detaylar',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            vm.state.step == BusinessStep.core
                                ? 'Ad, adres ve işletme türünü seç.'
                                : 'Neler var? (menü + özellikler)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTokens.muted, fontSize: 13, height: 1.35),
                          ),
                          const SizedBox(height: 14),

                          if (vm.state.error != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTokens.danger.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTokens.danger.withValues(alpha: 0.25)),
                              ),
                              child: Text(vm.state.error!, style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(height: 10),
                          ],

                          AppCard(
                            child: vm.state.step == BusinessStep.core
                                ? _Step1Core(vm: vm, formKey: _formKey)
                                : _Step2Details(vm: vm),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              if (vm.state.step == BusinessStep.details)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: vm.state.isLoading ? null : vm.backStep,
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: AppTokens.border),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    child: const Text('Geri', style: TextStyle(fontWeight: FontWeight.w900)),
                                  ),
                                ),
                              if (vm.state.step == BusinessStep.details) const SizedBox(width: 10),

                              Expanded(
                                child: GradientButton(
                                  text: vm.state.isLoading
                                      ? (vm.state.step == BusinessStep.core ? 'Devam...' : 'Oluşturuluyor...')
                                      : (vm.state.step == BusinessStep.core ? 'Devam' : 'İşletmeyi Oluştur'),
                                  isLoading: vm.state.isLoading,
                                  onPressed: vm.state.isLoading
                                      ? null
                                      : () async {
                                    if (vm.state.step == BusinessStep.core) {
                                      // Form validate + next
                                      final ok = _formKey.currentState?.validate() ?? false;
                                      if (!ok) return;
                                      vm.nextStep();
                                      return;
                                    }

                                    // submit (tek RPC)
                                    final busId = await vm.submitCreateBusiness();
                                    if (!mounted) return;

                                    if (busId != null) {
                                      Navigator.pushReplacementNamed(context, '/panel/dashboard');
                                    }
                                  },
                                ),
                              ),
                            ],
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

class _Step1Core extends StatelessWidget {
  final BusinessOnboardingViewModel vm;
  final GlobalKey<FormState> formKey;

  const _Step1Core({required this.vm, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          AppTextField(
            label: 'İşletme adı',
            hint: 'Örn: İz Cafe',
            controller: vm.nameController,
            validator: (v) => (v ?? '').trim().length < 2 ? 'İşletme adı gerekli' : null,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Adres',
            hint: 'Örn: Ankara / Yenimahalle',
            controller: vm.addressController,
            validator: (v) => (v ?? '').trim().length < 5 ? 'Adres gerekli' : null,
          ),
          const SizedBox(height: 14),

          _SectionTitle('İşletme türleri'),
          const SizedBox(height: 8),
          _ChipGrid<BizType>(
            items: BizType.values,
            isSelected: (t) => vm.selectedTypes.contains(t),
            labelOf: (t) => t.label,
            onTap: (t) {
              if (vm.selectedTypes.contains(t)) {
                vm.selectedTypes.remove(t);
              } else {
                vm.selectedTypes.add(t);
              }
              vm.state = vm.state.copyWith(error: null);
              vm.notifyListeners();
            },
          ),
        ],
      ),
    );
  }
}

class _Step2Details extends StatelessWidget {
  final BusinessOnboardingViewModel vm;
  const _Step2Details({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionTitle('Menü / Neler var?'),
        const SizedBox(height: 8),
        _ChipGrid<Offering>(
          items: Offering.values,
          isSelected: (o) => vm.selectedOfferings.contains(o),
          labelOf: (o) => o.label,
          onTap: (o) {
            if (vm.selectedOfferings.contains(o)) {
              vm.selectedOfferings.remove(o);
            } else {
              vm.selectedOfferings.add(o);
            }
            vm.notifyListeners();
          },
        ),

        const SizedBox(height: 14),
        _SectionTitle('Özellikler'),
        const SizedBox(height: 8),

        ...BizFeature.values.map((f) {
          final v = vm.features[f] ?? false;
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTokens.border),
            ),
            child: Row(
              children: [
                Expanded(child: Text(f.label, style: const TextStyle(fontWeight: FontWeight.w900))),
                Switch(
                  value: v,
                  onChanged: (nv) {
                    vm.features[f] = nv;
                    vm.notifyListeners();
                  },
                  activeColor: AppTokens.primary,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
      ),
    );
  }
}

class _ChipGrid<T> extends StatelessWidget {
  final List<T> items;
  final bool Function(T) isSelected;
  final String Function(T) labelOf;
  final void Function(T) onTap;

  const _ChipGrid({
    required this.items,
    required this.isSelected,
    required this.labelOf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((it) {
        final selected = isSelected(it);
        return InkWell(
          onTap: () => onTap(it),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTokens.border),
              color: selected
                  ? AppTokens.primary.withValues(alpha: 0.14)
                  : Colors.white,
            ),
            child: Text(
              labelOf(it),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: selected ? AppTokens.text : AppTokens.text,
                fontSize: 12.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
