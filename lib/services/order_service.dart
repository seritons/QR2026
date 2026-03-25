import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient _sb;

  OrderService(this._sb);

  Future<List<Map<String, dynamic>>> fetchPanelOrders({
    required String businessId,
    int limit = 50,
  }) async {
    final res = await _sb.rpc(
      'get_panel_orders',
      params: {
        'p_business_id': businessId,
        'p_limit': limit,
      },
    );

    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _sb.rpc(
      'update_panel_order_status',
      params: {
        'p_order_id': orderId,
        'p_status': status,
      },
    );
  }

  RealtimeChannel subscribeOrders({
    required String businessId,
    required void Function(Map<String, dynamic> row) onInsert,
    required void Function(Map<String, dynamic> row) onUpdate,
  }) {
    final channel = _sb.channel('panel-orders-$businessId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'orders',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'business_id',
          value: businessId,
        ),
        callback: (payload) => onInsert(payload.newRecord),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'orders',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'business_id',
          value: businessId,
        ),
        callback: (payload) {
          debugPrint('[OrdersRealtime][INSERT] ${payload.newRecord}');
          onInsert(payload.newRecord);
        },
      )
      .subscribe((status, [error]) {
        debugPrint('[OrdersRealtime] status=$status error=$error');
      });

    return channel;
  }

  Future<void> disposeChannel(RealtimeChannel? channel) async {
    if (channel == null) return;
    await _sb.removeChannel(channel);
  }
}