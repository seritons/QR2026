import 'package:flutter/foundation.dart';

import '../../features/panel/orders/orders_model.dart';

class OrderSession extends ChangeNotifier {
  final Map<String, OrderListItemModel> _byId = {};

  List<OrderListItemModel> get allSorted {
    final list = _byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  bool get isEmpty => _byId.isEmpty;
  bool get isNotEmpty => _byId.isNotEmpty;
  int get count => _byId.length;

  OrderListItemModel? byId(String orderId) => _byId[orderId];

  void seed(List<OrderListItemModel> orders, {bool notify = true}) {
    _byId
      ..clear()
      ..addEntries(orders.map((e) => MapEntry(e.id, e)));

    if (notify) {
      notifyListeners();
    }
  }

  void upsert(OrderListItemModel order, {bool notify = true}) {
    _byId[order.id] = order;

    if (notify) {
      notifyListeners();
    }
  }

  void upsertMany(List<OrderListItemModel> orders, {bool notify = true}) {
    for (final order in orders) {
      _byId[order.id] = order;
    }

    if (notify) {
      notifyListeners();
    }
  }

  void mergeRealtimeRow(Map<String, dynamic> row, {bool notify = true}) {
    final id = (row['id'] ?? '').toString();
    if (id.isEmpty) return;

    final existing = _byId[id];

    final next = OrderListItemModel.fromJson({
      ...?existing?.toJson(),
      ...row,
      'item_count': row['item_count'] ?? existing?.itemCount ?? 0,
      'items_preview': (row['items_preview'] ?? '').toString().isNotEmpty
          ? row['items_preview']
          : (existing?.itemsPreview ?? ''),
      'total_text': row['total_text'] ?? existing?.totalText,
      'elapsed_text': row['elapsed_text'] ?? existing?.elapsedText,
      'order_no': row['order_no'] ?? existing?.orderNo,
      'source_label': row['source_label'] ?? existing?.sourceLabel,
      'customer_label': row['customer_label'] ?? existing?.customerLabel,
      'customer_full_name': row['customer_full_name'] ?? existing?.customerName,
      'customer_phone': row['customer_phone'] ?? existing?.customerPhone,
      'table_code': row['table_code'] ?? existing?.tableCode,
      'fulfillment_type': row['fulfillment_type'] ?? existing?.fulfillmentType,
      'business_id': row['business_id'] ?? existing?.businessId,
      'total_amount': row['total_amount'] ?? existing?.totalAmount,
      'status': row['status'] ?? existing?.status.toDb(),
      'created_at':
      row['created_at'] ?? existing?.createdAt.toIso8601String(),
      'updated_at':
      row['updated_at'] ?? existing?.updatedAt.toIso8601String(),
    });

    _byId[next.id] = next;

    if (notify) {
      notifyListeners();
    }
  }

  void remove(String orderId, {bool notify = true}) {
    _byId.remove(orderId);

    if (notify) {
      notifyListeners();
    }
  }

  List<OrderListItemModel> visible(OrderFilter filter) {
    final list = allSorted;

    switch (filter) {
      case OrderFilter.all:
        return list
            .where((e) =>
        e.status == OrderStatus.pending ||
            e.status == OrderStatus.confirmed ||
            e.status == OrderStatus.preparing ||
            e.status == OrderStatus.ready)
            .toList();

      case OrderFilter.pending:
        return list.where((e) => e.status == OrderStatus.pending).toList();

      case OrderFilter.confirmed:
        return list.where((e) => e.status == OrderStatus.confirmed).toList();

      case OrderFilter.preparing:
        return list.where((e) => e.status == OrderStatus.preparing).toList();

      case OrderFilter.ready:
        return list.where((e) => e.status == OrderStatus.ready).toList();

      case OrderFilter.cancelled:
        return list.where((e) => e.status == OrderStatus.cancelled).toList();
    }
  }

  List<OrderSummaryMetric> buildSummary() {
    final all = allSorted;
    final now = DateTime.now();

    final activeCount = all.where((e) =>
    e.status == OrderStatus.pending ||
        e.status == OrderStatus.confirmed ||
        e.status == OrderStatus.preparing).length;

    final todayOrders = all.where((e) =>
    e.createdAt.year == now.year &&
        e.createdAt.month == now.month &&
        e.createdAt.day == now.day);

    final todayCount = todayOrders.length;

    final todayRevenue = todayOrders
        .where((e) => e.status != OrderStatus.cancelled)
        .fold<double>(0, (sum, e) => sum + e.totalAmount);

    final readyCount =
        all.where((e) => e.status == OrderStatus.ready).length;

    return [
      OrderSummaryMetric(
        id: 'active',
        title: 'Aktif',
        value: '$activeCount',
        iconName: 'receipt_long',
      ),
      OrderSummaryMetric(
        id: 'today_total',
        title: 'Bugün',
        value: '$todayCount',
        iconName: 'shopping_bag',
      ),
      OrderSummaryMetric(
        id: 'revenue',
        title: 'Ciro',
        value: '₺${todayRevenue.toStringAsFixed(0)}',
        iconName: 'payments',
      ),
      OrderSummaryMetric(
        id: 'ready',
        title: 'Hazır',
        value: '$readyCount',
        iconName: 'schedule',
      ),
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'orders': _byId.values.map((e) => e.toJson()).toList(),
    };
  }

  void hydrateFromJson(Map<String, dynamic>? json, {bool notify = true}) {
    if (json == null) {
      clear(notify: notify);
      return;
    }

    final rawList = (json['orders'] as List?) ?? const [];

    final List<OrderListItemModel> parsed = <OrderListItemModel>[];

    for (final item in rawList) {
      if (item is Map) {
        parsed.add(
          OrderListItemModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        );
      }
    }

    seed(parsed, notify: notify);
  }

  void clear({bool notify = true}) {
    _byId.clear();

    if (notify) {
      notifyListeners();
    }
  }
}