import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/sessions/order_session.dart';
import '../../../services/order_service.dart';
import 'orders_model.dart';

class OrdersViewModel extends ChangeNotifier {
  final String businessId;
  final OrderService service;
  final OrderSession session;

  OrdersViewModel({
    required this.businessId,
    required this.service,
    required this.session,
  });

  bool isLoading = false;
  bool isStatusUpdating = false;
  String? error;
  String? actionError;

  OrderFilter selectedFilter = OrderFilter.all;
  List<OrderSummaryMetric> summary = const [];
  RealtimeChannel? _channel;

  OrderListItemModel? selectedOrder;

  List<OrderListItemModel> get visibleOrders => session.visible(selectedFilter);

  Future<void> init() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final rows = await service.fetchPanelOrders(businessId: businessId);
      final orders = rows.map(OrderListItemModel.fromJson).toList();

      session.seed(orders);
      summary = session.buildSummary();

      _channel = service.subscribeOrders(
        businessId: businessId,
        onInsert: _handleRealtimeInsert,
        onUpdate: _handleRealtimeUpdate,
      );
    } catch (e, st) {
      debugPrint('[OrdersVM.init] error=$e');
      debugPrint('$st');
      error = 'Siparişler yüklenemedi';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _handleRealtimeInsert(Map<String, dynamic> row) {
    session.mergeRealtimeRow(row);
    _syncSelectedOrder(row);
    summary = session.buildSummary();
    notifyListeners();
  }

  void _handleRealtimeUpdate(Map<String, dynamic> row) {
    session.mergeRealtimeRow(row);
    _syncSelectedOrder(row);
    summary = session.buildSummary();
    notifyListeners();
  }

  void _syncSelectedOrder(Map<String, dynamic> row) {
    final id = (row['id'] ?? '').toString();
    if (selectedOrder == null || selectedOrder!.id != id) return;

    selectedOrder = OrderListItemModel.fromJson(row);
  }

  void setFilter(OrderFilter filter) {
    if (selectedFilter == filter) return;
    selectedFilter = filter;
    notifyListeners();
  }

  void openOrder(String orderId) {
    final match = session.visible(OrderFilter.all).cast<OrderListItemModel?>().firstWhere(
          (e) => e?.id == orderId,
      orElse: () => null,
    );

    if (match == null) return;

    selectedOrder = match;
    actionError = null;
    notifyListeners();
  }

  void clearSelectedOrder() {
    selectedOrder = null;
    actionError = null;
    notifyListeners();
  }

  bool canAdvance(OrderStatus status) {
    return status == OrderStatus.pending ||
        status == OrderStatus.confirmed ||
        status == OrderStatus.preparing;
  }

  String advanceLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Siparişi Onayla';
      case OrderStatus.confirmed:
        return 'Hazırlamaya Başla';
      case OrderStatus.preparing:
        return 'Hazır Olarak İşaretle';
      case OrderStatus.ready:
        return 'Hazır';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  OrderStatus nextStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return OrderStatus.confirmed;
      case OrderStatus.confirmed:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.ready;
      case OrderStatus.ready:
        return OrderStatus.ready;
      case OrderStatus.cancelled:
        return OrderStatus.cancelled;
    }
  }

  Future<void> advanceOrder() async {
    final order = selectedOrder;
    if (order == null) return;
    if (!canAdvance(order.status)) return;

    final next = nextStatus(order.status);

    try {
      isStatusUpdating = true;
      actionError = null;
      notifyListeners();

      await service.updateOrderStatus(
        orderId: order.id,
        status: next.toDb(),
      );

      final updated = order.copyWith(
        status: next,
        updatedAt: DateTime.now(),
        elapsedText: OrderListItemModel.buildElapsedText(order.createdAt),
      );

      selectedOrder = updated;
      session.mergeRealtimeRow(updated.toJson());
      summary = session.buildSummary();
    } catch (e, st) {
      debugPrint('[OrdersVM.advanceOrder] error=$e');
      debugPrint('$st');
      actionError = 'Sipariş durumu güncellenemedi';
    } finally {
      isStatusUpdating = false;
      notifyListeners();
    }
  }

  Future<void> cancelOrder() async {
    final order = selectedOrder;
    if (order == null) return;
    if (order.status == OrderStatus.ready || order.status == OrderStatus.cancelled) return;

    try {
      isStatusUpdating = true;
      actionError = null;
      notifyListeners();

      await service.updateOrderStatus(
        orderId: order.id,
        status: OrderStatus.cancelled.toDb(),
      );

      final updated = order.copyWith(
        status: OrderStatus.cancelled,
        updatedAt: DateTime.now(),
      );

      selectedOrder = updated;
      session.mergeRealtimeRow(updated.toJson());
      summary = session.buildSummary();
    } catch (e, st) {
      debugPrint('[OrdersVM.cancelOrder] error=$e');
      debugPrint('$st');
      actionError = 'Sipariş iptal edilemedi';
    } finally {
      isStatusUpdating = false;
      notifyListeners();
    }
  }

  void onSummaryTap(String id) {
    switch (id) {
      case 'pending':
        setFilter(OrderFilter.pending);
        break;
      case 'confirmed':
        setFilter(OrderFilter.confirmed);
        break;
      case 'preparing':
        setFilter(OrderFilter.preparing);
        break;
      case 'ready':
        setFilter(OrderFilter.ready);
        break;
      default:
        setFilter(OrderFilter.all);
    }
  }

  Future<void> disposeAsync() async {
    await service.disposeChannel(_channel);
    _channel = null;
  }
}