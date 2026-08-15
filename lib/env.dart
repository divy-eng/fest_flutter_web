import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl {
    const String compileValue = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    );
    if (compileValue.isNotEmpty) return compileValue;
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get supabaseAnonKey {
    const String compileValue = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    );
    if (compileValue.isNotEmpty) return compileValue;

    const String legacyCompileValue = String.fromEnvironment(
      'SUPABASE_KEY',
      defaultValue: '',
    );
    if (legacyCompileValue.isNotEmpty) return legacyCompileValue;

    return dotenv.env['SUPABASE_ANON_KEY'] ?? dotenv.env['SUPABASE_KEY'] ?? '';
  }

  static String get supabaseKey => supabaseAnonKey;
}
