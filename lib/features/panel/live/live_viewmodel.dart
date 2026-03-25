import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'live_models.dart';

class LiveViewModel extends ChangeNotifier {
  bool isLoading = false;

  List<LiveMetricModel> metrics = const [];
  List<LiveAlertModel> alerts = const [];
  List<LiveOrderCardModel> liveOrders = const [];
  List<LiveQuickActionModel> quickActions = const [];
  LiveBusinessSnapshotModel? snapshot;

  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 250));

    metrics = const [
      LiveMetricModel(
        title: 'Aktif Sipariş',
        value: '18',
        icon: Icons.receipt_long_rounded,
        deltaText: '+4 son 1 sa.',
      ),
      LiveMetricModel(
        title: 'Bekleyen',
        value: '3',
        icon: Icons.timelapse_rounded,
        deltaText: '2 kritik',
      ),
      LiveMetricModel(
        title: 'Dolu Masa',
        value: '12/20',
        icon: Icons.table_restaurant_rounded,
        deltaText: '%60 doluluk',
      ),
      LiveMetricModel(
        title: 'Ciro',
        value: '₺8.420',
        icon: Icons.payments_rounded,
        deltaText: 'bugün',
      ),
    ];

    alerts = const [
      LiveAlertModel(
        id: 'a1',
        title: '2 sipariş uzun süredir bekliyor',
        subtitle: '10 dakikayı aşan siparişleri kontrol et.',
        icon: Icons.warning_amber_rounded,
      ),
      LiveAlertModel(
        id: 'a2',
        title: '1 masa doğrulama bekliyor',
        subtitle: 'QR oturumu manuel inceleme istiyor.',
        icon: Icons.qr_code_scanner_rounded,
      ),
    ];

    liveOrders = const [
      LiveOrderCardModel(
        id: 'o1',
        title: '#1042 • İç 4',
        subtitle: '2 Latte • 1 Cookie',
        status: LiveOrderStatus.pending,
        itemCount: 3,
        elapsedText: '2 dk',
        badge: 'Yeni',
      ),
      LiveOrderCardModel(
        id: 'o2',
        title: '#1041 • Dış 2',
        subtitle: '1 Burger • 1 Cola',
        status: LiveOrderStatus.preparing,
        itemCount: 2,
        elapsedText: '7 dk',
      ),
      LiveOrderCardModel(
        id: 'o3',
        title: '#1039 • Paket',
        subtitle: '2 Americano',
        status: LiveOrderStatus.ready,
        itemCount: 2,
        elapsedText: '1 dk',
        badge: 'Hazır',
      ),
    ];

    quickActions = const [
      LiveQuickActionModel(
        id: 'qa_orders',
        title: 'Siparişler',
        icon: Icons.receipt_long_rounded,
      ),
      LiveQuickActionModel(
        id: 'qa_business',
        title: 'İşletme',
        icon: Icons.storefront_rounded,
      ),
      LiveQuickActionModel(
        id: 'qa_menu',
        title: 'Menü',
        icon: Icons.menu_book_rounded,
      ),
      LiveQuickActionModel(
        id: 'qa_qr',
        title: 'QR',
        icon: Icons.qr_code_rounded,
      ),
    ];

    snapshot = const LiveBusinessSnapshotModel(
      topProduct: 'Iced Latte',
      activeCampaign: '%10 Kahve Saatleri',
      qrScansToday: '94',
      occupancyText: '%60 doluluk',
    );

    isLoading = false;
    notifyListeners();
  }

  void onQuickActionTap(String id) {
    debugPrint('[LiveVM] quickAction=$id');
  }

  void openOrder(String id) {
    debugPrint('[LiveVM] openOrder=$id');
  }
}