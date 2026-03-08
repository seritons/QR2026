import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_typography.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final disabled = onPressed == null || isLoading;

    return Opacity(
      opacity: disabled ? 0.65 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(tokens.rLg),
        onTap: disabled ? null : onPressed,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: tokens.appetiteGradient(),
            borderRadius: BorderRadius.circular(tokens.rLg),

            boxShadow: [
              BoxShadow(
                color: tokens.primary.withValues(alpha: .15),
                blurRadius: 48,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: isLoading
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : Text(
            text,
            style: AppTypography.button.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}