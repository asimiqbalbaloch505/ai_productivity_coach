import 'package:supabase_flutter/supabase_flutter.dart';

class DBHelper {
  static const supabaseUrl = 'https://bdtrjbosmvvsrflbaxyo.supabase.co';
  static const supabasePublishableKey =
      'sb_publishable_po1A_Ti8a126mYqfX2XLzA_s3JnaFXq';

  static Future<void> init() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
  }
}