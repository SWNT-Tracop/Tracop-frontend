class AppConfig {
  static String get apiBaseUrl =>
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000');

  static String get privacyPolicyVersion =>
      String.fromEnvironment('PRIVACY_POLICY_VERSION', defaultValue: 'v0-draft');

  static const Locale defaultLocale = Locale('es', 'CO');
}
