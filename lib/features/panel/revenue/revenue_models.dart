import 'package:flutter/material.dart';

class RevenueSummaryModel {
  final String dateLabel;
  final String revenueText;
  final String orderCountText;
  final String avgOrderText;
  final String compareText;

  const RevenueSummaryModel({
    required this.dateLabel,
    required this.revenueText,
    required this.orderCountText,
    required this.avgOrderText,
    required this.compareText,
  });
}

class RevenueBreakdownItemModel {
  final String label;
  final String revenueText;
  final String orderCountText;
  final IconData icon;

  const RevenueBreakdownItemModel({
    required this.label,
    required this.revenueText,
    required this.orderCountText,
    required this.icon,
  });
}

enum RevenueRangeType {
  day,
  week,
  month,
}