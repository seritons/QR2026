// lib/app/models/social_models.dart

// =====================
// SOCIAL COUNTS / STATE
// =====================
class SocialStatsModel {
  final int likeCount;
  final int messageCount;
  final int reportCount;

  /// Kullanıcıya özel (opsiyonel): ben like attım mı?
  final bool? viewerLiked;

  const SocialStatsModel({
    this.likeCount = 0,
    this.messageCount = 0,
    this.reportCount = 0,
    this.viewerLiked,
  });

  SocialStatsModel copyWith({
    int? likeCount,
    int? messageCount,
    int? reportCount,
    bool? viewerLiked,
    bool setViewerLiked = false,
  }) {
    return SocialStatsModel(
      likeCount: likeCount ?? this.likeCount,
      messageCount: messageCount ?? this.messageCount,
      reportCount: reportCount ?? this.reportCount,
      viewerLiked: setViewerLiked ? viewerLiked : this.viewerLiked,
    );
  }

  Map<String, dynamic> toJson() => {
    'likeCount': likeCount,
    'messageCount': messageCount,
    'reportCount': reportCount,
    if (viewerLiked != null) 'viewerLiked': viewerLiked,
  };

  factory SocialStatsModel.fromJson(Map<String, dynamic> json) {
    int _i(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;

    return SocialStatsModel(
      likeCount: _i(json['likeCount']),
      messageCount: _i(json['messageCount']),
      reportCount: _i(json['reportCount']),
      viewerLiked: (json['viewerLiked'] is bool) ? json['viewerLiked'] as bool : null,
    );
  }
}

// =====================
// COMMENT (Business or Product)
// =====================

enum CommentTargetType { business, product }

CommentTargetType commentTargetTypeFromString(String s) {
  final v = s.trim().toLowerCase();
  if (v == 'business') return CommentTargetType.business;
  return CommentTargetType.product;
}

class CommentAuthorModel {
  final String userId;
  final String name; // UI için "Furkan Çırak" gibi tek alan da olabilir
  final String? avatarUrl;

  const CommentAuthorModel({
    required this.userId,
    required this.name,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
  };

  factory CommentAuthorModel.fromJson(Map<String, dynamic> json) {
    return CommentAuthorModel(
      userId: (json['userId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      avatarUrl: json['avatarUrl'] == null ? null : json['avatarUrl'].toString(),
    );
  }
}

class CommentModel {
  final String id;

  /// Hedef: business ya da product
  final CommentTargetType targetType;
  final String targetId;

  final CommentAuthorModel author;

  /// 1..5 arası (opsiyonel). MVP’de rating istiyorsan aç.
  final int? rating;

  final String text;

  /// ISO string ya da server timestamp string (senin standardına göre)
  final String createdAt;

  /// Yorumun social sayıları (like count vs.) istersen
  final SocialStatsModel? social;

  const CommentModel({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.author,
    required this.text,
    required this.createdAt,
    this.rating,
    this.social,
  });

  CommentModel copyWith({
    String? text,
    int? rating,
    SocialStatsModel? social,
    bool setSocial = false,
  }) {
    return CommentModel(
      id: id,
      targetType: targetType,
      targetId: targetId,
      author: author,
      text: text ?? this.text,
      createdAt: createdAt,
      rating: rating ?? this.rating,
      social: setSocial ? social : this.social,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'targetType': targetType.name,
    'targetId': targetId,
    'author': author.toJson(),
    'text': text,
    'createdAt': createdAt,
    if (rating != null) 'rating': rating,
    if (social != null) 'social': social!.toJson(),
  };

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final authorMap = Map<String, dynamic>.from((json['author'] ?? const {}) as Map);
    final socialRaw = json['social'];

    return CommentModel(
      id: (json['id'] ?? '').toString(),
      targetType: CommentTargetType.values.firstWhere(
            (e) => e.name == (json['targetType'] ?? 'product').toString(),
        orElse: () => CommentTargetType.product,
      ),
      targetId: (json['targetId'] ?? '').toString(),
      author: CommentAuthorModel.fromJson(authorMap),
      text: (json['text'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      rating: (json['rating'] is num) ? (json['rating'] as num).toInt() : int.tryParse('${json['rating']}'),
      social: (socialRaw is Map) ? SocialStatsModel.fromJson(Map<String, dynamic>.from(socialRaw)) : null,
    );
  }
}

// =====================
// REPORT (Product-focused for now)
// =====================

/// Ürün report türleri (ürüne özel enum istedin)
enum ProductReportReason {
  wrongInfo,          // yanlış bilgi
  priceMismatch,      // fiyat yanlış
  notAvailable,       // ürün yok / stokta değil ama görünüyor
  inappropriate,      // uygunsuz içerik
  scam,               // dolandırıcılık / sahte
  other,              // diğer
}

ProductReportReason productReportReasonFromString(String s) {
  final v = s.trim().toLowerCase();
  for (final r in ProductReportReason.values) {
    if (r.name.toLowerCase() == v) return r;
  }
  return ProductReportReason.other;
}

enum ReportTargetType { product, business, comment } // şimdilik product odaklı ama genişleyebilir

ReportTargetType reportTargetTypeFromString(String s) {
  final v = s.trim().toLowerCase();
  if (v == 'business') return ReportTargetType.business;
  if (v == 'comment') return ReportTargetType.comment;
  return ReportTargetType.product;
}

class ReportModel {
  final String id;

  /// raporu atan user
  final String reporterUserId;

  /// hedef
  final ReportTargetType targetType;
  final String targetId;

  /// Product için enum reason. (Business/Comment raporları ileride başka enum isterse genişletirsin)
  final ProductReportReason reason;

  /// serbest açıklama
  final String? message;

  /// createdAt string
  final String createdAt;

  /// moderasyon durumu (opsiyonel)
  final bool? resolved;
  final String? resolvedAt;

  const ReportModel({
    required this.id,
    required this.reporterUserId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.createdAt,
    this.message,
    this.resolved,
    this.resolvedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'reporterUserId': reporterUserId,
    'targetType': targetType.name,
    'targetId': targetId,
    'reason': reason.name,
    'createdAt': createdAt,
    if (message != null) 'message': message,
    if (resolved != null) 'resolved': resolved,
    if (resolvedAt != null) 'resolvedAt': resolvedAt,
  };

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: (json['id'] ?? '').toString(),
      reporterUserId: (json['reporterUserId'] ?? '').toString(),
      targetType: ReportTargetType.values.firstWhere(
            (e) => e.name == (json['targetType'] ?? 'product').toString(),
        orElse: () => ReportTargetType.product,
      ),
      targetId: (json['targetId'] ?? '').toString(),
      reason: productReportReasonFromString((json['reason'] ?? 'other').toString()),
      createdAt: (json['createdAt'] ?? '').toString(),
      message: json['message'] == null ? null : json['message'].toString(),
      resolved: (json['resolved'] is bool) ? json['resolved'] as bool : null,
      resolvedAt: json['resolvedAt'] == null ? null : json['resolvedAt'].toString(),
    );
  }
}
