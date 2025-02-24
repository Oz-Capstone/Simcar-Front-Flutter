import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  /// ✅ 모든 API 요청에서 사용할 공통 헤더 생성
  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionCookie = prefs.getString('session_cookie'); // 저장된 JSESSIONID 가져오기

    return {
      "Content-Type": "application/json; charset=UTF-8",
      "Accept": "*/*",
      if (sessionCookie != null) "Cookie": sessionCookie, // ✅ 모든 요청에 JSESSIONID 포함
    };
  }

    /// ✅ 세션 삭제 (로그아웃 또는 회원탈퇴 시 호출)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_cookie'); // ✅ 세션 쿠키 삭제
    print("🗑️ 세션 쿠키 삭제 완료");
  }
}