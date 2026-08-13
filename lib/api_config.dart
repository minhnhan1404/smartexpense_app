import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const String serverIp = 'seat-buildings-scanners-here.trycloudflare.com';
  
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1/SmartExpense/public/api';
    try {
      if (Platform.isAndroid) return 'https://$serverIp/SmartExpense/public/api';
    } catch (e) {}
    return 'http://127.0.0.1/SmartExpense/public/api';
  }

  static String getUrl(String endpoint) {
    return '$baseUrl/$endpoint';
  }
}
