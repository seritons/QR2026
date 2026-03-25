import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_typography.dart';
import '../../../app/theme/tokens.dart';
import 'live_models.dart';
import 'live_viewmodel.dart';

class LiveView extends StatefulWidget {
  const LiveView({super.key});

  @override
  State<LiveView> createState() => _LiveViewState();
}

class _LiveViewState extends State<LiveView> {
  late final LiveViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = LiveViewModel();
    vm.init();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: vm,
      child: Consumer<LiveViewModel>(
        builder: (context, vm, _) {
          final tokens = Theme.of(context).extension<AppTokens>()!;

          if (vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              _LiveIntroCard(),
              const SizedBox(height: 12),

              _MetricsGrid(metrics: vm.metrics),
              const SizedBox(height: 14),

              if (vm.alerts.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Dikkat Gerektirenler',
                  actionText: 'Tümünü Gör',
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                ...vm.alerts.map(
                      (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AlertCard(model: e),
                  ),
                ),
                const SizedBox(height: 4),
              ],

              _SectionHeader(
                title: 'Canlı Siparişler',
                actionText: 'Siparişlere Git',
                onTap: () {},
              ),
              const SizedBox(height: 8),
              ...vm.liveOrders.map(
                    (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LiveOrderCard(
                    model: e,
                    onTap: () => vm.openOrder(e.id),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              if (vm.snapshot != null) ...[
                _SectionHeader(
                  title: 'İşletme Özeti',
                  actionText: null,
                  onTap: null,
                ),
                const SizedBox(height: 8),
                _BusinessSnapshotCard(model: vm.snapshot!),
                const SizedBox(height: 4),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _LiveIntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bugün neler oluyor?',
              style: AppTypography.title.copyWith(
                color: tokens.text,
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onTap;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.title.copyWith(
              color: tokens.text,
            ),
          ),
        ),
        if (actionText != null && onTap != null)
          TextButton(
            onPressed: onTap,
            child: Text(
              actionText!,
              style: AppTypography.bodyStrong.copyWith(
                color: tokens.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final List<LiveMetricModel> metrics;

  const _MetricsGrid({
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: metrics.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.48,
      ),
      itemBuilder: (_, index) => _MetricCard(model: metrics[index]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final LiveMetricModel model;

  const _MetricCard({
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              model.icon,
              size: 20,
              color: tokens.primary,
            ),
            const Spacer(),
            Text(
              model.title,
              style: AppTypography.caption.copyWith(
                color: tokens.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              model.value,
              style: AppTypography.metricSm.copyWith(
                color: tokens.text,
              ),
            ),
            if (model.deltaText != null) ...[
              const SizedBox(height: 4),
              Text(
                model.deltaText!,
                style: AppTypography.caption.copyWith(
                  color: tokens.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final LiveAlertModel model;

  const _AlertCard({
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tokens.primarySoft,
                borderRadius: BorderRadius.circular(tokens.rMd),
              ),
              child: Icon(
                model.icon,
                size: 18,
                color: tokens.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.title,
                    style: AppTypography.bodyStrong.copyWith(
                      color: tokens.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model.subtitle,
                    style: AppTypography.caption.copyWith(
                      color: tokens.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveOrderCard extends StatelessWidget {
  final LiveOrderCardModel model;
  final VoidCallback onTap;

  const _LiveOrderCard({
    required this.model,
    required this.onTap,
  });

  Color _statusColor(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    switch (model.status) {
      case LiveOrderStatus.pending:
        return tokens.warning;
      case LiveOrderStatus.preparing:
        return tokens.info;
      case LiveOrderStatus.ready:
        return tokens.success;
    }
  }

  String _statusText() {
    switch (model.status) {
      case LiveOrderStatus.pending:
        return 'Bekliyor';
      case LiveOrderStatus.preparing:
        return 'Hazırlanıyor';
      case LiveOrderStatus.ready:
        return 'Hazır';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final statusColor = _statusColor(context);

    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(tokens.rLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 56,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            model.title,
                            style: AppTypography.bodyStrong.copyWith(
                              color: tokens.text,
                            ),
                          ),
                        ),
                        if (model.badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              model.badge!,
                              style: AppTypography.caption.copyWith(
                                color: statusColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      model.subtitle,
                      style: AppTypography.caption.copyWith(
                        color: tokens.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        Text(
                          _statusText(),
                          style: AppTypography.caption.copyWith(
                            color: statusColor,
                          ),
                        ),
                        Text(
                          '${model.itemCount} ürün',
                          style: AppTypography.caption.copyWith(
                            color: tokens.muted,
                          ),
                        ),
                        Text(
                          model.elapsedText,
                          style: AppTypography.caption.copyWith(
                            color: tokens.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: tokens.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessSnapshotCard extends StatelessWidget {
  final LiveBusinessSnapshotModel model;

  const _BusinessSnapshotCard({
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          children: [
            _SnapshotRow(label: 'Top Ürün', value: model.topProduct),
            const SizedBox(height: 12),
            _SnapshotRow(label: 'Aktif Kampanya', value: model.activeCampaign),
            const SizedBox(height: 12),
            _SnapshotRow(label: 'Bugünkü QR', value: model.qrScansToday),
            const SizedBox(height: 12),
            _SnapshotRow(label: 'Doluluk', value: model.occupancyText),
          ],
        ),
      ),
    );
  }
}

class _SnapshotRow extends StatelessWidget {
  final String label;
  final String value;

  const _SnapshotRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              color: tokens.muted,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyStrong.copyWith(
            color: tokens.text,
          ),
        ),
      ],
    );
  }
}
