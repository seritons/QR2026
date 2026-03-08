import 'package:flutter/material.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/app_card.dart';

class PanelDashboardView extends StatelessWidget {
  const PanelDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(height: 40, color: tokens.bg),

                    Text(
                      'Hoş geldin 👋',
                      style: AppTypography.title.copyWith(
                        color: tokens.text,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Brightness: ${Theme.of(context).brightness}',
                      style: AppTypography.caption.copyWith(
                        color: tokens.muted,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Burası şu an MVP dashboard. Sonraki adım: günlük ciro, popüler ürün, saatlik yoğunluk.',
                      style: AppTypography.body.copyWith(
                        color: tokens.muted,
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

                          Text(
                            'Günlük Ciro',
                            style: AppTypography.bodyStrong.copyWith(
                              color: tokens.text,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            '₺0',
                            style: AppTypography.metric.copyWith(
                              color: tokens.text,
                            ),
                          ),
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

                          Text(
                            'Müşteri',
                            style: AppTypography.bodyStrong.copyWith(
                              color: tokens.text,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            '0',
                            style: AppTypography.metric.copyWith(
                              color: tokens.text,
                            ),
                          ),
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

                    Text(
                      'Son İşlemler',
                      style: AppTypography.bodyStrong.copyWith(
                        color: tokens.text,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Henüz veri yok.',
                      style: AppTypography.body.copyWith(
                        color: tokens.muted,
                      ),
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