enum PanelAccessStatus { allowed }

class LoginState {
  final bool isLoading;
  final String? error;
  final bool isSignedIn;

  // NEW:
  final bool hasBusiness;
  final String? businessId;

  const LoginState({
    this.isLoading = false,
    this.error,
    this.isSignedIn = false,
    this.hasBusiness = false,
    this.businessId,
  });

  LoginState copyWith({
    bool? isLoading,
    String? error,
    bool? isSignedIn,
    bool? hasBusiness,
    String? businessId,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      hasBusiness: hasBusiness ?? this.hasBusiness,
      businessId: businessId ?? this.businessId,
    );
  }
}
