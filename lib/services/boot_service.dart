import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BootService {
  final SupabaseClient _sb;
  BootService(this._sb);

  void _log(String msg) => debugPrint('[BootService] $msg');

  /// RPC: public.login_boot()
  /// returns: jsonb map
  Future<Map<String, dynamic>> loginBoot() async {
    _log('loginBoot START');

    try {
      final res = await _sb.rpc('login_boot');

      if (res == null || res is! Map) {
        _log('loginBoot FAIL invalid response type=${res.runtimeType}');
        throw Exception('login_boot invalid response');
      }

      final map = (res as Map).cast<String, dynamic>();
      _log('loginBoot DONE keys=${map.keys.toList()}');
      return map;
    } catch (e, st) {
      _log('loginBoot ERROR=$e');
      _log('stack=$st');
      rethrow;
    }
  }

  /// RPC: public.get_business_full(p_business_id uuid)
  Future<Map<String, dynamic>> getBusinessFull({
    required String businessId,
  }) async {
    final id = businessId.trim();
    _log('getBusinessFull START businessId="$id"');

    if (id.isEmpty) {
      throw ArgumentError('businessId empty');
    }

    try {
      final res = await _sb.rpc(
        'get_business_full',
        params: {'p_business_id': id},
      );

      if (res == null || res is! Map) {
        _log('getBusinessFull FAIL invalid response type=${res.runtimeType}');
        throw Exception('get_business_full invalid response');
      }

      final map = (res as Map).cast<String, dynamic>();
      _log('getBusinessFull DONE keys=${map.keys.toList()}');
      return map;
    } catch (e, st) {
      _log('getBusinessFull ERROR=$e');
      _log('stack=$st');
      rethrow;
    }
  }
}
