import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/cookie_service.dart';

class JoinPage extends StatefulWidget {
  const JoinPage({super.key});

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  // 이메일
  bool isEmailTouched = false;
  bool isEmailValid = true;
  String emailError = '';

  // 비밀번호
  bool isPasswordTouched = false;
  bool isPasswordValid = true;
  String passwordError = '';

  // 이름
  bool isNameTouched = false;
  bool isNameValid = true;
  String nameError = '';

  // 전화번호
  bool isPhoneTouched = false;
  bool isPhoneValid = true;
  String phoneError = '';

  void _validateEmail(String value) {
    setState(() {
      isEmailTouched = true;
      if (value.isEmpty) {
        isEmailValid = false;
        emailError = '이메일은 필수입니다';
      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
        isEmailValid = false;
        emailError = '이메일 형식이 올바르지 않습니다';
      } else {
        isEmailValid = true;
        emailError = '';
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      isPasswordTouched = true;
      if (value.isEmpty) {
        isPasswordValid = false;
        passwordError = '비밀번호는 필수입니다';
      } else if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$').hasMatch(value)) {
        isPasswordValid = false;
        passwordError = '비밀번호는 8자 이상, 문자와 숫자를 포함해야 합니다';
      } else {
        isPasswordValid = true;
        passwordError = '';
      }
    });
  }

  void _validateName(String value) {
    setState(() {
      isNameTouched = true;
      if (value.trim().isEmpty) {
        isNameValid = false;
        nameError = '이름은 필수입니다';
      } else {
        isNameValid = true;
        nameError = '';
      }
    });
  }

  void _validatePhone(String value) {
    setState(() {
      isPhoneTouched = true;
      if (value.trim().isEmpty) {
        isPhoneValid = false;
        phoneError = '전화번호는 필수입니다';
      } else if (!RegExp(r'^\d{2,3}-\d{3,4}-\d{4}$').hasMatch(value)) {
        isPhoneValid = false;
        phoneError = '전화번호 형식이 올바르지 않습니다 (예: 010-1234-5678)';
      } else {
        isPhoneValid = true;
        phoneError = '';
      }
    });
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required bool isTouched,
    required bool isValid,
    required String errorMessage,
    required void Function(String) onChanged,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          onTap: () {
            if (!isTouched) {
              onChanged(controller.text); // 터치 시 유효성 검사 시작
            }
          },
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        if (isTouched)
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.cancel,
                color: isValid ? Colors.blue : Colors.red,
                size: 18,
              ),
              const SizedBox(width: 6),
              if (!isValid)
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
            ],
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _register(BuildContext context) async {
    // 모든 필드 유효성 검사 강제 실행
    _validateEmail(emailController.text);
    _validatePassword(passwordController.text);
    _validateName(nameController.text);
    _validatePhone(phoneController.text);

    // 하나라도 유효하지 않으면 중단
    if (!(isEmailValid && isPasswordValid && isNameValid && isPhoneValid)) return;

    try {
      final response = await http.post(
        Uri.parse("https://simcar.kro.kr/api/members/join"),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
          "name": nameController.text.trim(),
          "phone": phoneController.text.trim()
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('가입이 완료되었습니다.')),
        );
      } else {
        final decodedBody = utf8.decode(response.bodyBytes);
        final responseData = jsonDecode(decodedBody);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData["message"] ?? "회원가입 실패")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("네트워크 오류: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField(
                label: '이메일',
                controller: emailController,
                isTouched: isEmailTouched,
                isValid: isEmailValid,
                errorMessage: emailError,
                onChanged: _validateEmail,
              ),
              _buildField(
                label: '비밀번호',
                controller: passwordController,
                isTouched: isPasswordTouched,
                isValid: isPasswordValid,
                errorMessage: passwordError,
                onChanged: _validatePassword,
                obscureText: true,
              ),
              _buildField(
                label: '이름',
                controller: nameController,
                isTouched: isNameTouched,
                isValid: isNameValid,
                errorMessage: nameError,
                onChanged: _validateName,
              ),
              _buildField(
                label: '전화번호',
                controller: phoneController,
                isTouched: isPhoneTouched,
                isValid: isPhoneValid,
                errorMessage: phoneError,
                onChanged: _validatePhone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _register(context),
                child: const Text('가입하기', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
