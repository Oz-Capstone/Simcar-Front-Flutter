import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 비동기 초기화
  await SharedPreferences.getInstance(); // SharedPreferences 초기화

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // ← 이거 추가!
      title: '오즈',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false, // 모든 페이지 제거
      );
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
