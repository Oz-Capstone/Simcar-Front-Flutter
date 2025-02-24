import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/cookie_service.dart';

class EditPage extends StatefulWidget {
  const EditPage({super.key});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = "";
  Map<int, bool> favoriteStatus = {};

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  // ✅ 프로필 정보 불러오기 (UTF-8 디코딩 추가)
  Future<void> _fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse("http://54.180.92.197:8080/api/members/profile"),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decodedData = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedData);
        setState(() {
          nameController.text = data['name'] ?? '';
          emailController.text = data['email'] ?? '';
          phoneController.text = data['phone'] ?? '';
        });
      } else {
        throw Exception('프로필 정보를 불러오지 못했습니다.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  // ✅ 프로필 정보 수정하기 (즉시 반영)
  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final response = await http.put(
        Uri.parse("http://54.180.92.197:8080/api/members/profile"),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          "name": nameController.text.trim(),
          "email": emailController.text.trim(),
          "phone": phoneController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        // ✅ 즉시 반영
        await _fetchProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('정보가 수정되었습니다.')),
        );

       // ✅ 수정된 정보를 pop()으로 전달
      Navigator.pop(context, {
        "name": nameController.text.trim(),
        "phone": phoneController.text.trim(),
      });

      } else if (response.body.isNotEmpty) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _errorMessage = data["message"] ?? "수정 실패";
        });
      } else {
        setState(() {
          _errorMessage = "서버 응답이 없습니다.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "네트워크 오류: $e";
      });
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
        title: const Text('회원정보수정'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),// ✅ 화면 터치 시 키보드 닫기
        child: SingleChildScrollView(
          child: Padding(
           padding: const EdgeInsets.all(16.0),
           child: Column(
             mainAxisSize: MainAxisSize.min, // ✅ 키보드 올라와도 높이 조절
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    "⚠️ 오류: $_errorMessage",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const Text(
                '기본정보입력',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
        
              _buildTextField('이름 *', nameController, enabled: true),
              const SizedBox(height: 20),
        
              _buildTextField('이메일 *', emailController, enabled: false),
              const SizedBox(height: 20),
        
              _buildTextField('전화번호 *', phoneController, keyboardType: TextInputType.phone),
              const SizedBox(height: 40),
        
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('수정'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
     ), 
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool enabled = true, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
