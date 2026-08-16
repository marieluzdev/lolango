class Env {
  /// Web Client ID pour Google Sign-In (utilisé comme serverClientId)
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// Android Client ID (utilisé automatiquement par le SDK Android)
  static const googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
  );

  /// Supabase URL
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase Anon Key
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
