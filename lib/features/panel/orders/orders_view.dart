import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/sessions/app_session.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/tokens.dart';
import '../../../services/app_service.dart';
import 'orders_model.dart';
import 'orders_viewmodel.dart';

class PanelOrdersView extends StatefulWidget {
  const PanelOrdersView({super.key});

  @override
  State<PanelOrdersView> createState() => _PanelOrdersViewState();
}

class _PanelOrdersViewState extends State<PanelOrdersView> {
  late final OrdersViewModel vm;

  @override
  void initState() {
    super.initState();

    final appSession = context.read<AppSession>();
    final appService = context.read<AppServices>();
    final businessId = appSession.business.business?.id;

    vm = OrdersViewModel(
      businessId: businessId ?? '',
      service: appService.order,
      session: appSession.orders,
    );
    vm.init();
  }

  @override
  void dispose() {
    vm.disposeAsync();
    super.dispose();
  }

  Future<void> _openOrderSheet(OrderListItemModel order) async {
    vm.openOrder(order.id);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: vm,
          child: const _OrderActionSheet(),
        );
      },
    );

    vm.clearSelectedOrder();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: vm,
      child: Consumer<OrdersViewModel>(
        builder: (context, vm, _) {
          final tokens = Theme.of(context).extension<AppTokens>()!;

          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
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
                        'Siparişler',
                        style: AppTypography.title.copyWith(color: tokens.text),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Aktif siparişleri yönet, durumlarını ilerlet.',
                        style: AppTypography.body.copyWith(color: tokens.muted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _OrderSummaryRow(
                items: vm.summary,
                onTap: vm.onSummaryTap,
              ),
              const SizedBox(height: 14),

              _OrderFilterChips(
                selected: vm.selectedFilter,
                onChanged: vm.setFilter,
              ),
              const SizedBox(height: 14),

              ...vm.visibleOrders.map(
                    (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OrderCard(
                    model: e,
                    onTap: () => _openOrderSheet(e),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderSummaryRow extends StatelessWidget {
  final List<OrderSummaryMetric> items;
  final ValueChanged<String> onTap;

  const _OrderSummaryRow({
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.map((item) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: item == items.last ? 0 : 10),
            child: _OrderSummaryCard(
              model: item,
              onTap: () => onTap(item.id),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final OrderSummaryMetric model;
  final VoidCallback onTap;

  const _OrderSummaryCard({
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
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(model.icon, color: tokens.primary, size: 18),
              const SizedBox(height: 8),
              Text(
                model.title,
                style: AppTypography.caption.copyWith(color: tokens.muted),
              ),
              const SizedBox(height: 4),
              Text(
                model.value,
                style: AppTypography.bodyStrong.copyWith(color: tokens.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderFilterChips extends StatelessWidget {
  final OrderFilter selected;
  final ValueChanged<OrderFilter> onChanged;

  const _OrderFilterChips({
    required this.selected,
    required this.onChanged,
  });

  String _label(OrderFilter f) {
    switch (f) {
      case OrderFilter.all:
        return 'Tümü';
      case OrderFilter.pending:
        return 'Bekliyor';
      case OrderFilter.confirmed:
        return 'Onaylandı';
      case OrderFilter.preparing:
        return 'Hazırlanıyor';
      case OrderFilter.ready:
        return 'Hazır';
      case OrderFilter.cancelled:
        return 'İptal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final values = OrderFilter.values;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: values.map((f) {
          final selectedNow = f == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_label(f)),
              selected: selectedNow,
              onSelected: (_) => onChanged(f),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderListItemModel model;
  final VoidCallback onTap;

  const _OrderCard({
    required this.model,
    required this.onTap,
  });

  Color _statusColor(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    switch (model.status) {
      case OrderStatus.pending:
        return tokens.warning;
      case OrderStatus.confirmed:
        return tokens.primary;
      case OrderStatus.preparing:
        return tokens.info;
      case OrderStatus.ready:
        return tokens.success;
      case OrderStatus.cancelled:
        return tokens.danger;
    }
  }

  String _statusText() => model.status.label;

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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 64,
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
                        Text(
                          model.orderNo,
                          style: AppTypography.bodyStrong.copyWith(
                            color: tokens.text,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          model.sourceLabel,
                          style: AppTypography.caption.copyWith(
                            color: tokens.muted,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          model.totalText,
                          style: AppTypography.bodyStrong.copyWith(
                            color: tokens.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      model.customerLabel,
                      style: AppTypography.caption.copyWith(
                        color: tokens.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      model.itemsPreview,
                      style: AppTypography.body.copyWith(
                        color: tokens.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
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
              Icon(Icons.chevron_right_rounded, color: tokens.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderActionSheet extends StatelessWidget {
  const _OrderActionSheet();

  Color _statusColor(BuildContext context, OrderStatus status) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    switch (status) {
      case OrderStatus.pending:
        return tokens.warning;
      case OrderStatus.confirmed:
        return tokens.primary;
      case OrderStatus.preparing:
        return tokens.info;
      case OrderStatus.ready:
        return tokens.success;
      case OrderStatus.cancelled:
        return tokens.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrdersViewModel>();
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final order = vm.selectedOrder;

    if (order == null) {
      return const SizedBox.shrink();
    }

    final statusColor = _statusColor(context, order.status);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Text(
                    order.orderNo,
                    style: AppTypography.title.copyWith(color: tokens.text),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    order.status.label,
                    style: AppTypography.caption.copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              order.customerName.isEmpty ? order.customerLabel : order.customerName,
              style: AppTypography.bodyStrong.copyWith(color: tokens.text),
            ),
            const SizedBox(height: 4),
            Text(
              order.customerPhone.isEmpty ? order.sourceLabel : order.customerPhone,
              style: AppTypography.body.copyWith(color: tokens.muted),
            ),
            const SizedBox(height: 4),
            Text(
              order.itemsPreview,
              style: AppTypography.body.copyWith(color: tokens.text),
            ),
            const SizedBox(height: 8),
            Text(
              'Toplam: ${order.totalText}',
              style: AppTypography.bodyStrong.copyWith(color: tokens.text),
            ),
            const SizedBox(height: 18),

            if (vm.actionError != null) ...[
              Text(
                vm.actionError!,
                style: AppTypography.caption.copyWith(color: tokens.danger),
              ),
              const SizedBox(height: 12),
            ],

            if (vm.canAdvance(order.status))
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: vm.isStatusUpdating ? null : vm.advanceOrder,
                  child: vm.isStatusUpdating
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(vm.advanceLabel(order.status)),
                ),
              ),

            if (order.status != OrderStatus.ready &&
                order.status != OrderStatus.cancelled) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: vm.isStatusUpdating ? null : vm.cancelOrder,
                  child: const Text('Siparişi İptal Et'),
                ),
              ),
            ],

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}