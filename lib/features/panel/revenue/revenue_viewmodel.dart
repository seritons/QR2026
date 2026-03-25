import 'package:flutter/material.dart';
import 'revenue_models.dart';

class RevenueViewModel extends ChangeNotifier {
  bool isLoading = false;

  RevenueRangeType selectedRange = RevenueRangeType.day;

  RevenueSummaryModel? summary;
  List<RevenueBreakdownItemModel> hourlyBreakdown = const [];

  Future<void> init({DateTime? initialDate}) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 250));

    summary = const RevenueSummaryModel(
      dateLabel: '8 Mart 2026',
      revenueText: '₺8.420',
      orderCountText: '124 sipariş',
      avgOrderText: '₺67,90 ort.',
      compareText: 'Düne göre +%12',
    );

    hourlyBreakdown = const [
      RevenueBreakdownItemModel(
        label: '09:00 - 11:00',
        revenueText: '₺920',
        orderCountText: '14 sipariş',
        icon: Icons.wb_sunny_outlined,
      ),
      RevenueBreakdownItemModel(
        label: '11:00 - 13:00',
        revenueText: '₺1.840',
        orderCountText: '28 sipariş',
        icon: Icons.local_cafe_outlined,
      ),
      RevenueBreakdownItemModel(
        label: '13:00 - 15:00',
        revenueText: '₺2.260',
        orderCountText: '33 sipariş',
        icon: Icons.lunch_dining_outlined,
      ),
      RevenueBreakdownItemModel(
        label: '15:00 - 18:00',
        revenueText: '₺1.520',
        orderCountText: '22 sipariş',
        icon: Icons.free_breakfast_outlined,
      ),
      RevenueBreakdownItemModel(
        label: '18:00 - 22:00',
        revenueText: '₺1.880',
        orderCountText: '27 sipariş',
        icon: Icons.nightlife_outlined,
      ),
    ];

    isLoading = false;
    notifyListeners();
  }

  void setRange(RevenueRangeType range) {
    if (selectedRange == range) return;
    selectedRange = range;
    notifyListeners();
  }

  void openBreakdown(String label) {
    debugPrint('[RevenueVM] openBreakdown=$label');
  }
}