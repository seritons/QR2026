import 'package:flutter/material.dart';

enum LiveOrderStatus {
  pending,
  preparing,
  ready,
}

class LiveMetricModel {
  final String title;
  final String value;
  final IconData icon;
  final String? deltaText;

  const LiveMetricModel({
    required this.title,
    required this.value,
    required this.icon,
    this.deltaText,
  });
}

class LiveAlertModel {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? accentColor;

  const LiveAlertModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accentColor,
  });
}

class LiveOrderCardModel {
  final String id;
  final String title;
  final String subtitle;
  final LiveOrderStatus status;
  final int itemCount;
  final String elapsedText;
  final String? badge;

  const LiveOrderCardModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.itemCount,
    required this.elapsedText,
    this.badge,
  });
}

class LiveQuickActionModel {
  final String id;
  final String title;
  final IconData icon;

  const LiveQuickActionModel({
    required this.id,
    required this.title,
    required this.icon,
  });
}

class LiveBusinessSnapshotModel {
  final String topProduct;
  final String activeCampaign;
  final String qrScansToday;
  final String occupancyText;

  const LiveBusinessSnapshotModel({
    required this.topProduct,
    required this.activeCampaign,
    required this.qrScansToday,
    required this.occupancyText,
  });
}