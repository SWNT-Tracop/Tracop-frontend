import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://localhost:3000');

  static const String privacyPolicyVersion = String.fromEnvironment(
      'PRIVACY_POLICY_VERSION',
      defaultValue: 'v0-draft');

  static const bool requireTls =
      bool.fromEnvironment('REQUIRE_TLS', defaultValue: true);

  static const bool enableCertPinning =
      bool.fromEnvironment('ENABLE_CERT_PINNING', defaultValue: false);

  static const bool allowOfflineAppEntry = bool.fromEnvironment(
    'ALLOW_OFFLINE_APP_ENTRY',
    defaultValue: false,
  );

  static const bool enableLocalMultiAccount = bool.fromEnvironment(
    'ENABLE_LOCAL_MULTI_ACCOUNT',
    defaultValue: false,
  );

  static bool get canEnterWithoutSession => kDebugMode && allowOfflineAppEntry;
  static bool get canUseLocalMultiAccount =>
      kDebugMode && enableLocalMultiAccount;

  static const String defaultLocale = 'es_CO';

  static const Locale locale = Locale(defaultLocale);

  AppConfig._();
}
