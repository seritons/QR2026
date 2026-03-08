// lib/features/panel/orders/orders_view.dart
import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/app_card.dart';

class PanelOrdersView extends StatelessWidget {
  const PanelOrdersView({super.key});

  @override
  Widget build(BuildContext context) {

    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Siparişler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('MVP: sipariş listesi burada olacak.', style: TextStyle(color: tokens.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
