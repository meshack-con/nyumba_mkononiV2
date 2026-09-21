/// Mipangilio ya jumla ya application - badilisha [baseUrl] kulingana
/// na mahali backend (FastAPI) inapokaa.
class AppConfig {
  AppConfig._();

  /// Backend ya FastAPI (umis_core). Kwa maendeleo ya local:
  ///   - Chrome/Web kwenye kompyuta hiyohiyo: http://127.0.0.1:8000
  ///   - Kifaa halisi/simulator kingine: badilisha kwa IP ya kompyuta yako
  static const String baseUrl = 'http://127.0.0.1:8000';

  static const String appName = 'UMIS Core';
  static const String appTagline = 'Umoja wa Vijana wa CCM';
  static const String appMotto = 'UMOJA • NGUVU • MAENDELEO';

  static const Duration requestTimeout = Duration(seconds: 30);
}
