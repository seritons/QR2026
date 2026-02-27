import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientProvider {
  static final String supabaseUrl =
  const String.fromEnvironment('SUPABASE_URL');

  static final String supabaseAnonKey =
  const String.fromEnvironment('SUPABASE_ANON_KEY');

  static Future<void> init() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('Supabase env missing');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
