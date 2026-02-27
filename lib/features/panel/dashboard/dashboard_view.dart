import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/app_card.dart';

class PanelDashboardView extends StatelessWidget {
  const PanelDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ÜST BAR ARTIK SHELL'DE (AppBar + Drawer + Logout)
              // burada sadece içerik kalıyor

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hoş geldin 👋',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Burası şu an MVP dashboard. Sonraki adım: günlük ciro, popüler ürün, saatlik yoğunluk.',
                      style: TextStyle(
                        color: AppTokens.muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Günlük Ciro', style: TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text('₺0', style: TextStyle(color: AppTokens.muted)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Müşteri', style: TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text('0', style: TextStyle(color: AppTokens.muted)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Son İşlemler', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(
                      'Henüz veri yok.',
                      style: TextStyle(color: AppTokens.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
