

import 'package:supabase_flutter/supabase_flutter.dart';

class DBHelper {
  static const String supabaseUrl =
      'https://bdtrjbosmvvsrflbaxyo.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkdHJqYm9zbXZ2c3JmbGJheHlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIwNzkwMjEsImV4cCI6MjEwNzY1NTAyMX0.rOCuioCjG5pmlc74E4QM4Zfx2NILtIJ9CkwWXoS9Dhg';

  static Future<void> init() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}