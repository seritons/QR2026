import 'package:qrpanel/app/models/social_models.dart';

class BusinessModel {
  final String id;
  final String name;
  final String address;
  final BusinessGeoModel? geo;

  /// DB’de meta içinde tutacağız dedin: features + diğer key’ler
  final List<String> features; // ["wifi","garden",...]
  final BusinessSocialModel? social;

  /// Sayımlar
  final SocialStatsModel socialStats;

  const BusinessModel({
    required this.id,
    required this.name,
    required this.address,
    this.geo,
    this.features = const [],
    this.social,
    this.socialStats = const SocialStatsModel(),
  });

  BusinessModel copyWith({
    String? name,
    String? address,
    BusinessGeoModel? geo,
    bool setGeo = false,
    List<String>? features,
    BusinessSocialModel? social,
    bool setSocial = false,
    List<CommentModel>? comments,
    SocialStatsModel? socialStats,
  }) {
    return BusinessModel(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      geo: setGeo ? geo : this.geo,
      features: features ?? this.features,
      social: setSocial ? social : this.social,
      socialStats: socialStats ?? this.socialStats,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    if (geo != null) 'geo': geo!.toJson(),
    'features': features,
    if (social != null) 'social': social!.toJson(),
    'socialStats': socialStats.toJson(),
  };

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    final rawFeatures = (json['features'] as List?)?.map((e)=>e.toString()).toList() ?? const [];
    final geoRaw = json['geo'];
    final socialRaw = json['social'];
    final statsRaw = json['socialStats'];

    return BusinessModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      geo: (geoRaw is Map) ? BusinessGeoModel.fromJson(Map<String, dynamic>.from(geoRaw)) : null,
      features: rawFeatures,
      social: (socialRaw is Map) ? BusinessSocialModel.fromJson(Map<String, dynamic>.from(socialRaw)) : null,
      socialStats: (statsRaw is Map)
          ? SocialStatsModel.fromJson(Map<String, dynamic>.from(statsRaw))
          : const SocialStatsModel(),
    );
  }
}


class BusinessGeoModel {
  final double lat;
  final double lng;

  const BusinessGeoModel({required this.lat, required this.lng});

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  factory BusinessGeoModel.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) => (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;

    return BusinessGeoModel(
      lat: _d(json['lat']),
      lng: _d(json['lng']),
    );
  }
}

/// meta.features içinde string list tutacağız dedin.
/// Bu enum’u sadece client tarafında “label standardı” için istiyorsan kullan.
/// DB’ye string olarak gider.
enum BusinessFeature {
  wifi,
  garden,
  kidsArea,
  wheelchairAccess,
  parking,
  petFriendly,
  outdoorSeating,
  powerOutlets,
}

BusinessFeature businessFeatureFromString(String s) {
  final v = s.trim().toLowerCase();
  for (final f in BusinessFeature.values) {
    if (f.name.toLowerCase() == v) return f;
  }
  return BusinessFeature.wifi;
}

class BusinessSocialModel {
  final String? instagram;
  final String? tiktok;
  final String? website;
  final String? phone;

  const BusinessSocialModel({
    this.instagram,
    this.tiktok,
    this.website,
    this.phone,
  });

  Map<String, dynamic> toJson() => {
    if (instagram != null) 'instagram': instagram,
    if (tiktok != null) 'tiktok': tiktok,
    if (website != null) 'website': website,
    if (phone != null) 'phone': phone,
  };

  factory BusinessSocialModel.fromJson(Map<String, dynamic> json) {
    return BusinessSocialModel(
      instagram: json['instagram'] == null ? null : json['instagram'].toString(),
      tiktok: json['tiktok'] == null ? null : json['tiktok'].toString(),
      website: json['website'] == null ? null : json['website'].toString(),
      phone: json['phone'] == null ? null : json['phone'].toString(),
    );
  }
}
