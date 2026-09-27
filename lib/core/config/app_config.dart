import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime configuration for the mobile app.
///
/// `--dart-define` values take precedence over the bundled `.env` file. This
/// matters for release builds because `.env` is copied into the application
/// bundle at build time and cannot be corrected after the APK is installed.
class AppConfig {
  static const _supabaseUrlOverride = String.fromEnvironment('SUPABASE_URL');
  static const _supabaseKeyOverride = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static String get supabaseUrl => _required(
    _supabaseUrlOverride.isNotEmpty
        ? _supabaseUrlOverride
        : dotenv.env['SUPABASE_URL'],
    'SUPABASE_URL',
  ).replaceFirst(RegExp(r'/+$'), '');

  static String get supabasePublishableKey => _required(
    _supabaseKeyOverride.isNotEmpty
        ? _supabaseKeyOverride
        : dotenv.env['SUPABASE_PUBLISHABLE_KEY'],
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static String _required(String? value, String name) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      throw StateError(
        '$name is missing. Configure it in .env or with --dart-define.',
      );
    }
    return trimmed;
  }
}
