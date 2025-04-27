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

  bool _isLoading = false;

  Future<void> _fetchMemberId() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionCookie = prefs.getString('session_cookie');

    if (sessionCookie == null) {
      print("❌ [오류] 저장된 JSESSIONID가 없습니다.");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("https://simcar.kro.kr/api/members/profile"),
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
          "Accept": "*/*",
          "Cookie": sessionCookie,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData.containsKey("memberId")) {
          await prefs.setString('memberId', responseData["memberId"].toString());
          // print("✅ memberId 저장 완료: \${responseData["memberId"]}");
        } else {
          print("⚠ memberId가 응답에 없음.");
        }
      } else {
        print("❌ [오류] 프로필 조회 실패: \${response.statusCode}");
      }
    } catch (e) {
      print("❌ [예외 발생]: \$e");
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
        Uri.parse("https://simcar.kro.kr/api/members/login"),
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
          "Accept": "*/*",
        },
        body: jsonEncode({"email": email, "password": password}),
      );

      print("🔍 로그인 응답 헤더: \${response.headers}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final prefs = await SharedPreferences.getInstance();
        final cookieHeader = response.headers['set-cookie'];

        if (cookieHeader != null) {
          final jsessionId = cookieHeader.split(';')[0];
          await prefs.setString('session_cookie', jsessionId);
          print("✅ 세션 저장 완료: \$jsessionId");

          await _fetchMemberId();
        } else {
          print("⚠ Set-Cookie가 응답에 없음.");
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
          (Route<dynamic> route) => false,
        );
      } else {
        final decodedBody = utf8.decode(response.bodyBytes);
        final responseData = jsonDecode(decodedBody);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData["message"] ?? "로그인 실패")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("네트워크 오류: \$e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(''),
            automaticallyImplyLeading: false,
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
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 100),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: '이메일'),
                ),
                const SizedBox(height: 10),
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
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('로그인'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const JoinPage()),
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
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            ),
          ),
      ],
    );
  }
}
