import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/cookie_service.dart';

class JoinPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  JoinPage({super.key});

  Future<void> _register(BuildContext context) async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    final String name = nameController.text.trim();
    final String phone = phoneController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("모든 항목을 입력하세요.")),
      );
      return;
    }
//http://54.180.92.197:8080
    try {
      final response = await http.post(
        Uri.parse("http://54.180.92.197:8080/api/members/join"), // 서버 IP 주소로 변경
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          "email": email,
          "password": password,
          "name": name,
          "phone": phone
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 회원가입 성공 시
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('가입이 완료되었습니다.')),
        );
      } else {
        // 회원가입 실패 시
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData["message"] ?? "회원가입 실패")),
        );
      }
    } catch (e) {
      // 네트워크 오류 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("네트워크 오류: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '회원가입',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: '이메일'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '이름'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: '전화번호'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _register(context),
              child: const Text('가입하기',
              style: TextStyle(
                color: Colors.white,
              ),
              ),
              style:ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.blue),
              )
            ),
          ],
        ),
      ),
    );
  }
}
