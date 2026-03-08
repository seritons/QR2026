import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.rLg),
        border: Border.all(color: tokens.border),
        boxShadow: tokens.shadow,
      ),
      child: child,
    );
  }
}