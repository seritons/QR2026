import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qrpanel/app/sessions/business_session.dart';
import '../../../../services/business_service.dart';
import 'models.dart';

class BusinessOnboardingViewModel extends ChangeNotifier {
  final BusinessService _biz;
  final BusinessSession _businessSession;

  BusinessOnboardingViewModel(this._biz, this._businessSession);

  BusinessOnboardingState state = const BusinessOnboardingState();

  // Step 1
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final Set<BizType> selectedTypes = {};

  // Step 2
  final Set<Offering> selectedOfferings = {};
  final Map<BizFeature, bool> features = {
    for (final f in BizFeature.values) f: false,
  };

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    super.dispose();
  }

  void _log(String msg) {
    if (kDebugMode) debugPrint('[BizOnboardingVM] $msg');
  }

  void _setLoading(bool v) {
    state = state.copyWith(isLoading: v, error: null);
    notifyListeners();
  }

  void _setError(Object e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString().replaceFirst('Exception: ', ''),
    );
    notifyListeners();
  }

  bool validateStep1() {
    final name = nameController.text.trim();
    final addr = addressController.text.trim();

    if (name.length < 2) {
      state = state.copyWith(error: 'İşletme adı gerekli');
      notifyListeners();
      return false;
    }
    if (addr.length < 5) {
      state = state.copyWith(error: 'Adres çok kısa');
      notifyListeners();
      return false;
    }
    if (selectedTypes.isEmpty) {
      state = state.copyWith(error: 'En az 1 işletme türü seç');
      notifyListeners();
      return false;
    }
    return true;
  }

  void nextStep() {
    if (state.isLoading) return;
    if (!validateStep1()) return;

    state = state.copyWith(step: BusinessStep.details, error: null);
    notifyListeners();
  }

  void backStep() {
    if (state.isLoading) return;
    state = state.copyWith(step: BusinessStep.core, error: null);
    notifyListeners();
  }

  Map<String, dynamic> _buildMeta() {
    final types = selectedTypes.map((e) => e.key).toList();

    final offerings = selectedOfferings.map((e) => e.key).toList();

    final featuresMap = <String, dynamic>{};
    for (final entry in features.entries) {
      featuresMap[entry.key.key] = entry.value;
    }

    return {
      "types": types,
      "offerings": offerings,
      "features": featuresMap,
    };
  }

  Future<String?> submitCreateBusiness() async {
    _setLoading(true);

    try {
      final name = nameController.text.trim();
      final address = addressController.text.trim();
      final meta = _buildMeta();

      _log('Submitting create_business_minimal...');
      _log('name="$name" addressLen=${address.length}');
      _log('meta=$meta');

      final bus = await _biz.createBusinessMinimal(
        name: name,
        address: address,
        meta: meta,
      );
      final busId = bus.id;
      _log('Business created id=$busId');

      state = state.copyWith(isLoading: false, error: null);
      _businessSession.setBusiness(bus);
      notifyListeners();
      return busId;
    } catch (e) {
      _setError(e);
      return null;
    }
  }
}
