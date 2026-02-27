// lib/services/business_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app/models/business_model.dart';

class BusinessService {
  final SupabaseClient _sb;
  BusinessService(this._sb);

  void _log(String msg) {
    // ignore: avoid_print
    print('[BusinessService] $msg');
  }

  /// ✅ Seçenek A:
  /// RPC: public.create_business_minimal(p_name, p_address, p_meta) -> jsonb { ok, business }
  /// Dönen full business JSON'u BusinessModel'e map'ler.
  Future<BusinessModel> createBusinessMinimal({
    required String name,
    required String address,
    Map<String, dynamic>? meta,
  }) async {
    final n = name.trim();
    final a = address.trim();

    if (n.length < 2) throw Exception('İşletme adı çok kısa');
    if (a.length < 5) throw Exception('Adres çok kısa');

    final payload = <String, dynamic>{
      'p_name': n,
      'p_address': a,
      'p_meta': meta ?? <String, dynamic>{},
    };

    _log('createBusinessMinimal RPC START name="$n" addrLen=${a.length}');
    final res = await _sb.rpc('create_business_minimal', params: payload);

    final json = (res as Map).cast<String, dynamic>();
    _log('createBusinessMinimal RPC DONE keys=${json.keys.toList()}');

    final ok = json['ok'] == true;
    if (!ok) {
      final reason = (json['reason'] ?? 'create_business_failed').toString();
      throw Exception('İşletme oluşturulamadı: $reason');
    }

    final rawBiz = (json['business'] as Map?)?.cast<String, dynamic>();
    if (rawBiz == null) throw Exception('RPC business missing');

    // ✅ DEBUG: burada patlıyor olma ihtimali yüksek
    _log('rawBiz keys=${rawBiz.keys.toList()}');

    final rawMeta = (rawBiz['meta'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    // ✅ BusinessModel’in beklediği shape’e normalize et
    final normalized = <String, dynamic>{
      'id': rawBiz['id'],
      'name': rawBiz['name'],
      'address': rawBiz['address'],

      // meta içinden çek
      'geo': rawMeta['geo'],
      'features': rawMeta['features'] ?? <dynamic>[],
      'social': rawMeta['social'],

      // defaultlar
      'comments': <dynamic>[],
      'socialStats': <String, dynamic>{
        'likeCount': rawMeta['likeCount'] ?? 0,
        'messageCount': rawMeta['messageCount'] ?? 0,
        'reportCount': rawMeta['reportCount'] ?? 0,
      },
    };

    try {
      final business = BusinessModel.fromJson(normalized);
      _log('createBusinessMinimal parsed businessId=${business.id} name="${business.name}"');
      return business;
    } catch (e) {
      _log('createBusinessMinimal fromJson ERROR=$e');
      _log('normalized=$normalized');
      rethrow;
    }
  }


  // ---- placeholders (ileride) ----
  Future<BusinessModel> fetchBusinessFull({required String businessId}) async {
    throw UnimplementedError();
  }

  Future<void> updateBusiness({required BusinessModel business}) async {
    throw UnimplementedError();
  }

  Future<void> deleteBusiness({required String businessId}) async {
    throw UnimplementedError();
  }
}
