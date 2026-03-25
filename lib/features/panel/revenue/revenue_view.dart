import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_typography.dart';
import '../../../app/theme/tokens.dart';
import 'revenue_models.dart';
import 'revenue_viewmodel.dart';

class RevenueView extends StatefulWidget {
  final DateTime? initialDate;

  const RevenueView({
    super.key,
    this.initialDate,
  });

  @override
  State<RevenueView> createState() => _RevenueViewState();
}

class _RevenueViewState extends State<RevenueView> {
  late final RevenueViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = RevenueViewModel();
    vm.init(initialDate: widget.initialDate);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: vm,
      child: Consumer<RevenueViewModel>(
        builder: (context, vm, _) {
          final tokens = Theme.of(context).extension<AppTokens>()!;

          if (vm.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final summary = vm.summary;
          if (summary == null) {
            return const Scaffold(
              body: Center(
                child: Text('Veri bulunamadı'),
              ),
            );
          }

          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                'Ciro',
                style: AppTypography.title.copyWith(color: tokens.text),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.dateLabel,
                          style: AppTypography.caption.copyWith(
                            color: tokens.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          summary.revenueText,
                          style: AppTypography.metricLg.copyWith(
                            color: tokens.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          summary.compareText,
                          style: AppTypography.bodyStrong.copyWith(
                            color: tokens.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _RevenueRangeChips(
                  selected: vm.selectedRange,
                  onChanged: vm.setRange,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _MiniMetricCard(
                        title: 'Sipariş',
                        value: summary.orderCountText,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniMetricCard(
                        title: 'Ortalama',
                        value: summary.avgOrderText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Text(
                  'Saatlik Kırılım',
                  style: AppTypography.title.copyWith(
                    color: tokens.text,
                  ),
                ),
                const SizedBox(height: 8),

                ...vm.hourlyBreakdown.map(
                      (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RevenueBreakdownCard(
                      model: e,
                      onTap: () => vm.openBreakdown(e.label),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RevenueRangeChips extends StatelessWidget {
  final RevenueRangeType selected;
  final ValueChanged<RevenueRangeType> onChanged;

  const _RevenueRangeChips({
    required this.selected,
    required this.onChanged,
  });

  String _label(RevenueRangeType type) {
    switch (type) {
      case RevenueRangeType.day:
        return 'Gün';
      case RevenueRangeType.week:
        return 'Hafta';
      case RevenueRangeType.month:
        return 'Ay';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: RevenueRangeType.values.map((type) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_label(type)),
              selected: selected == type,
              onSelected: (_) => onChanged(type),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MiniMetricCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.caption.copyWith(
                color: tokens.muted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTypography.bodyStrong.copyWith(
                color: tokens.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueBreakdownCard extends StatelessWidget {
  final RevenueBreakdownItemModel model;
  final VoidCallback onTap;

  const _RevenueBreakdownCard({
    required this.model,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(tokens.rLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tokens.primarySoft,
                  borderRadius: BorderRadius.circular(tokens.rMd),
                ),
                child: Icon(
                  model.icon,
                  color: tokens.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.label,
                      style: AppTypography.bodyStrong.copyWith(
                        color: tokens.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      model.orderCountText,
                      style: AppTypography.caption.copyWith(
                        color: tokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    model.revenueText,
                    style: AppTypography.bodyStrong.copyWith(
                      color: tokens.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: tokens.muted,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}