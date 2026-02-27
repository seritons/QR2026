enum RegisterStep { adminAuth, done }

class RegisterState {
  final RegisterStep step;
  final bool isLoading;
  final String? error;

  const RegisterState({
    this.step = RegisterStep.adminAuth,
    this.isLoading = false,
    this.error,
  });

  RegisterState copyWith({
    RegisterStep? step,
    bool? isLoading,
    String? error,
  }) {
    return RegisterState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
