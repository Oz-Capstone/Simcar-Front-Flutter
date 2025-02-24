import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'join.dart';
import 'package:app/buy/home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false; // 로딩 상태

  /// ✅ 로그인 후 memberId 가져오는 함수
Future<void> _fetchMemberId() async {
  final prefs = await SharedPreferences.getInstance();
  final sessionCookie = prefs.getString('session_cookie');

  if (sessionCookie == null) {
    print("❌ [오류] 저장된 JSESSIONID가 없습니다.");
    return;
  }

  try {
    final response = await http.get(
      Uri.parse("http://54.180.92.197:8080/api/members/profile"),
      headers: {
        "Content-Type": "application/json; charset=UTF-8",
        "Accept": "*/*",
        "Cookie": sessionCookie, // ✅ JSESSIONID 포함
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData.containsKey("memberId")) {
        await prefs.setString('memberId', responseData["memberId"].toString());
        print("✅ memberId 저장 완료: ${responseData["memberId"]}");
      } else {
        print("⚠ `memberId`가 응답에 없음.");
      }
    } else {
      print("❌ [오류] 프로필 조회 실패: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ [예외 발생]: $e");
  }
}


  Future<void> _login() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이메일과 비밀번호를 입력하세요.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("http://54.180.92.197:8080/api/members/login"), // 서버의 실제 IP
           headers: { 
            "Content-Type": "application/json; charset=UTF-8",
            "Accept": "*/*",
              },
           body: jsonEncode({"email": email, "password": password}),
            );
              print("🔍 로그인 응답 헤더: ${response.headers}");


      if (response.statusCode >= 200 && response.statusCode < 300) {
       final prefs = await SharedPreferences.getInstance();
       final cookieHeader = response.headers['set-cookie'];

        // ✅ JSESSIONID 저장
        if (cookieHeader != null) {
          final jsessionId = cookieHeader.split(';')[0]; // "JSESSIONID=..." 추출
          await prefs.setString('session_cookie', jsessionId);
          print("✅ 세션 저장 완료: $jsessionId");
        
           // ✅ 로그인 후 `memberId` 가져오기
          await _fetchMemberId();
        } else {
          print("⚠ `Set-Cookie`가 응답에 없음.");
        }


        // 로그인 성공
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
          (Route<dynamic> route) => false, // 모든 페이지 제거
        );
      } else {
        // 로그인 실패 (에러 메시지 표시)
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData["message"] ?? "로그인 실패")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("네트워크 오류: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(''),
        automaticallyImplyLeading: false, // 뒤로가기 버튼 삭제
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Simcar',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text(
              '당신의 중고차를 뽑아보세요!',
              style: TextStyle(
                fontSize: 15,
                color: Colors.blue[300],
              ),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: '이메일'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _login, // 로그인 API 호출
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator() // 로딩 상태
                      : const Text('로그인',),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => JoinPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('회원가입'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
