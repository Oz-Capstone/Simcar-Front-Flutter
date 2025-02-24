import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _preferences;

  // SharedPreferences 초기화
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // JSESSIONID 저장
  static Future<void> setSessionCookie(String sessionId) async {
    await _preferences?.setString('session_cookie', sessionId);
  }

  // JSESSIONID 가져오기
  static String? getSessionCookie() {
    return _preferences?.getString('session_cookie');
  }

  // JSESSIONID 삭제 (로그아웃 시 사용)
  static Future<void> clearSession() async {
    await _preferences?.remove('session_cookie');
  }
}
