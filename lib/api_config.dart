import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Thay đổi IP này thành IP Wi-Fi của máy tính bạn hoặc tên miền khi lên Store
  static const String serverIp = '172.16.0.150'; // IP Wi-Fi hiện tại của bạn
  
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1/SmartExpense/public/api';
    try {
      if (Platform.isAndroid) return 'http://$serverIp/SmartExpense/public/api';
    } catch (e) {}
    return 'http://127.0.0.1/SmartExpense/public/api';
  }

  // Tiện ích nối đường dẫn
  static String getUrl(String endpoint) {
    return '$baseUrl/$endpoint';
  }
}
