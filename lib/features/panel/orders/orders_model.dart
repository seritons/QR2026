import 'package:flutter/material.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  cancelled;

  static OrderStatus fromDb(String? value) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  static OrderStatus fromJson(dynamic value) {
    if (value == null) return OrderStatus.pending;
    return fromDb(value.toString());
  }

  String toDb() {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String toJson() => toDb();

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Onay Bekliyor';
      case OrderStatus.confirmed:
        return 'Onaylandı';
      case OrderStatus.preparing:
        return 'Hazırlanıyor';
      case OrderStatus.ready:
        return 'Hazır';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }
}

enum OrderFilter {
  all,
  pending,
  confirmed,
  preparing,
  ready,
  cancelled;

  static OrderFilter fromJson(dynamic value) {
    switch (value?.toString()) {
      case 'all':
        return OrderFilter.all;
      case 'pending':
        return OrderFilter.pending;
      case 'confirmed':
        return OrderFilter.confirmed;
      case 'preparing':
        return OrderFilter.preparing;
      case 'ready':
        return OrderFilter.ready;
      case 'cancelled':
        return OrderFilter.cancelled;
      default:
        return OrderFilter.all;
    }
  }

  String toJson() {
    switch (this) {
      case OrderFilter.all:
        return 'all';
      case OrderFilter.pending:
        return 'pending';
      case OrderFilter.confirmed:
        return 'confirmed';
      case OrderFilter.preparing:
        return 'preparing';
      case OrderFilter.ready:
        return 'ready';
      case OrderFilter.cancelled:
        return 'cancelled';
    }
  }
}

class OrderSummaryMetric {
  final String id;
  final String title;
  final String value;
  final String iconName;

  const OrderSummaryMetric({
    required this.id,
    required this.title,
    required this.value,
    required this.iconName,
  });

  factory OrderSummaryMetric.fromJson(Map<String, dynamic> json) {
    return OrderSummaryMetric(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      iconName: (json['icon_name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'value': value,
      'icon_name': iconName,
    };
  }

  IconData get icon {
    switch (iconName) {
      case 'receipt_long':
        return Icons.receipt_long_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'payments':
        return Icons.payments_rounded;
      case 'schedule':
        return Icons.schedule_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  OrderSummaryMetric copyWith({
    String? id,
    String? title,
    String? value,
    String? iconName,
  }) {
    return OrderSummaryMetric(
      id: id ?? this.id,
      title: title ?? this.title,
      value: value ?? this.value,
      iconName: iconName ?? this.iconName,
    );
  }
}

class OrderListItemModel {
  final String id;
  final String businessId;
  final String orderNo;
  final String sourceLabel;
  final String customerLabel;
  final String customerName;
  final String customerPhone;
  final String tableCode;
  final String fulfillmentType;
  final String itemsPreview;
  final String totalText;
  final double totalAmount;
  final String elapsedText;
  final OrderStatus status;
  final int itemCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderListItemModel({
    required this.id,
    required this.businessId,
    required this.orderNo,
    required this.sourceLabel,
    required this.customerLabel,
    required this.customerName,
    required this.customerPhone,
    required this.tableCode,
    required this.fulfillmentType,
    required this.itemsPreview,
    required this.totalText,
    required this.totalAmount,
    required this.elapsedText,
    required this.status,
    required this.itemCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderListItemModel.fromJson(Map<String, dynamic> json) {
    final totalAmount = _toDouble(json['total_amount']);
    final createdAt = _parseDate(json['created_at']);
    final updatedAt = _parseDate(json['updated_at']) ?? createdAt ?? DateTime.now();

    final safeCreatedAt = createdAt ?? DateTime.now();
    final tableCode = (json['table_code'] ?? '').toString().trim();
    final fulfillmentType = (json['fulfillment_type'] ?? 'table').toString();
    final id = (json['id'] ?? '').toString();

    return OrderListItemModel(
      id: id,
      businessId: (json['business_id'] ?? '').toString(),
      orderNo: (json['order_no'] ?? '').toString().isNotEmpty
          ? json['order_no'].toString()
          : _buildOrderNo(id),
      sourceLabel: (json['source_label'] ?? '').toString().isNotEmpty
          ? json['source_label'].toString()
          : _buildSourceLabel(
        fulfillmentType: fulfillmentType,
        tableCode: tableCode,
      ),
      customerLabel: (json['customer_label'] ?? '').toString().isNotEmpty
          ? json['customer_label'].toString()
          : _buildCustomerLabel(fulfillmentType),
      customerName: (json['customer_full_name'] ?? '').toString(),
      customerPhone: (json['customer_phone'] ?? '').toString(),
      tableCode: tableCode,
      fulfillmentType: fulfillmentType,
      itemsPreview: (json['items_preview'] ?? '').toString().isEmpty
          ? 'Ürün detayı yok'
          : json['items_preview'].toString(),
      totalText: (json['total_text'] ?? '').toString().isNotEmpty
          ? json['total_text'].toString()
          : _buildTotalText(totalAmount),
      totalAmount: totalAmount,
      elapsedText: (json['elapsed_text'] ?? '').toString().isNotEmpty
          ? json['elapsed_text'].toString()
          : buildElapsedText(safeCreatedAt),
      status: OrderStatus.fromJson(json['status']),
      itemCount: _toInt(json['item_count']),
      createdAt: safeCreatedAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'order_no': orderNo,
      'source_label': sourceLabel,
      'customer_label': customerLabel,
      'customer_full_name': customerName,
      'customer_phone': customerPhone,
      'table_code': tableCode,
      'fulfillment_type': fulfillmentType,
      'items_preview': itemsPreview,
      'total_text': totalText,
      'total_amount': totalAmount,
      'elapsed_text': elapsedText,
      'status': status.toJson(),
      'item_count': itemCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  OrderListItemModel copyWith({
    String? id,
    String? businessId,
    String? orderNo,
    String? sourceLabel,
    String? customerLabel,
    String? customerName,
    String? customerPhone,
    String? tableCode,
    String? fulfillmentType,
    String? itemsPreview,
    String? totalText,
    double? totalAmount,
    String? elapsedText,
    OrderStatus? status,
    int? itemCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderListItemModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      orderNo: orderNo ?? this.orderNo,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      customerLabel: customerLabel ?? this.customerLabel,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      tableCode: tableCode ?? this.tableCode,
      fulfillmentType: fulfillmentType ?? this.fulfillmentType,
      itemsPreview: itemsPreview ?? this.itemsPreview,
      totalText: totalText ?? this.totalText,
      totalAmount: totalAmount ?? this.totalAmount,
      elapsedText: elapsedText ?? this.elapsedText,
      status: status ?? this.status,
      itemCount: itemCount ?? this.itemCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String buildElapsedText(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);

    if (diff.inMinutes < 1) return 'Şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk';
    if (diff.inHours < 24) return '${diff.inHours} sa';
    return '${diff.inDays} g';
  }

  static String _buildOrderNo(String id) {
    if (id.isEmpty) return '#------';
    final shortId = id.replaceAll('-', '');
    final cut = shortId.length >= 6 ? shortId.substring(0, 6) : shortId;
    return '#${cut.toUpperCase()}';
  }

  static String _buildSourceLabel({
    required String fulfillmentType,
    required String tableCode,
  }) {
    if (fulfillmentType == 'table') {
      return tableCode.isEmpty ? 'Masa' : tableCode;
    }
    return 'Gel-Al';
  }

  static String _buildCustomerLabel(String fulfillmentType) {
    if (fulfillmentType == 'table') return 'Masa Siparişi';
    return 'Gel-Al Siparişi';
  }

  static String _buildTotalText(double total) {
    return '₺${total.toStringAsFixed(0)}';
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}