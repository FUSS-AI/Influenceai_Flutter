/// Runtime configuration for the InfluenceAI Flutter demo.
///
/// Values are injected at build time via `--dart-define`:
/// ```
/// flutter run --dart-define=API_BASE_URL=http://... --dart-define=API_KEY=sk_...
/// ```
class AppConfig {
  AppConfig._();

  /// Base URL for the soulchat-ai API gateway.
  /// External team → soulchat-ai → InfluenceAI (internal, not directly accessible).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8005/client/v1/influencer',
  );

  /// Your platform API key (issued by the platform team).
  /// Use 'sk_dev_testkey' for local testing.
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: 'sk_dev_testkey',
  );
}
