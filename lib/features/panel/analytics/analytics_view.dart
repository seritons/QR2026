// lib/features/panel/analytics/analytics_view.dart
import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/app_card.dart';

class PanelAnalyticsView extends StatelessWidget {
  const PanelAnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Analiz', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('MVP: ciro trendi / yoğunluk / top ürün burada.', style: TextStyle(color: AppTokens.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
