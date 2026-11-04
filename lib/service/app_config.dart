class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  static String baseUrl = "https://karaoke.simbillsoft.in/api/";
  static String? accessToken;
  static String? counterID;
  static int? customerId;
  static String? customerName;
  static String? customerNumber;
  static String? settings;
  static int? version = 1;
}
