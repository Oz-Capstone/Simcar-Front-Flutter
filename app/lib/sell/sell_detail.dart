// import 생략 없이 전체 포함
import 'package:app/sell/home.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../services/cookie_service.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';

class CarRegisterPage extends StatefulWidget {
  const CarRegisterPage({super.key});

  @override
  _CarRegisterPageState createState() => _CarRegisterPageState();
}

class _CarRegisterPageState extends State<CarRegisterPage> {
  int _currentStep = 0;
  XFile? _imageFile;
  final picker = ImagePicker();
  bool _isCustomInput = false;
  bool _isSubmitting = false; // ✅ 등록 중 상태

  final Map<String, dynamic> carRequest = {
    "type": "",
    "price": 0,
    "brand": "",
    "model": "",
    "year": 0,
    "mileage": 0,
    "fuelType": "",
    "carNumber": "",
    "insuranceHistory": 0,
    "inspectionHistory": 0,
    "color": "",
    "transmission": "",
    "region": "",
    "contactNumber": ""
  };

  final List<String> fields = [
    "차량 종류", "가격", "브랜드", "모델", "연식", "주행거리",
    "연료 타입", "차 번호", "보험이력", "검사이력", "색깔", "변속기", "지역", "전화번호"
  ];

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _customInputController = TextEditingController();

  final Map<String, List<String>> dropdownOptions = {
    "차량 종류": ["세단", "SUV", "트럭", "쿠페", "해치백", "직접 입력"],
    "브랜드": ["현대", "기아", "BMW", "벤츠", "아우디", "직접 입력"],
    "모델": ["소나타", "아반떼", "카니발", "K5", "그랜저", "직접 입력"],
    "연식": ["2012", "2013", "2014", "2015", "2016", "직접 입력"],
    "연료 타입": ["가솔린", "디젤", "전기", "하이브리드", "직접 입력"],
    "보험이력": ["1회", "2회", "3회", "4회", "5회", "직접 입력"],
    "검사이력": ["1회", "2회", "3회", "4회", "5회", "직접 입력"],
    "색깔": ["흰색", "검정색", "회색", "파란색", "빨간색", "직접 입력"],
    "변속기": ["자동", "수동", "직접 입력"],
    "지역": ["서울", "부산", "대구", "인천", "광주", "직접 입력"]
  };

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  void _nextStep() {
    String key = carRequest.keys.elementAt(_currentStep);
    String input = _isCustomInput ? _customInputController.text.trim() : _controller.text.trim();

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("값을 입력하거나 선택해주세요.")),
      );
      return;
    }

    setState(() {
      carRequest[key] = input;
      _controller.clear();
      _customInputController.clear();
      _isCustomInput = false;
      _currentStep++;
    });
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        String key = carRequest.keys.elementAt(_currentStep);
        if (_isCustomInput) {
          _customInputController.text = carRequest[key]?.toString() ?? "";
        } else {
          _controller.text = carRequest[key]?.toString() ?? "";
        }
      });
    }
  }

  Future<void> _uploadCarInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionCookie = prefs.getString('session_cookie');

    if (sessionCookie == null || sessionCookie.isEmpty) {
      print("❌ [오류] 저장된 JSESSIONID가 없습니다.");
      return;
    }

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이미지를 선택해주세요.")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true; // ✅ 로딩 시작
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://simcar.kro.kr/api/cars"),
      );

      request.headers.addAll({
        "Content-Type": "multipart/form-data",
        "Accept": "*/*",
        "Cookie": sessionCookie,
      });

      request.files.add(
        http.MultipartFile.fromString(
          'request',
          jsonEncode({
            "type": carRequest["type"],
            "price": int.parse(carRequest["price"].toString()),
            "brand": carRequest["brand"],
            "model": carRequest["model"],
            "year": int.parse(carRequest["year"].toString()),
            "mileage": int.parse(carRequest["mileage"].toString()),
            "fuelType": carRequest["fuelType"],
            "carNumber": carRequest["carNumber"],
            "insuranceHistory": int.tryParse(carRequest["insuranceHistory"].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
            "inspectionHistory": int.tryParse(carRequest["inspectionHistory"].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
            "color": carRequest["color"],
            "transmission": carRequest["transmission"],
            "region": carRequest["region"],
            "contactNumber": carRequest["contactNumber"],
          }),
          contentType: MediaType('application', 'json'),
        ),
      );

      final mimeType = lookupMimeType(_imageFile!.path) ?? 'image/png';
      final mimeSplit = mimeType.split('/');
      request.files.add(await http.MultipartFile.fromPath(
        'images',
        _imageFile!.path,
        contentType: MediaType(mimeSplit[0], mimeSplit[1]),
      ));

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🚗 차량이 성공적으로 등록되었습니다.')),
        );
        Navigator.pop(context, MaterialPageRoute(builder: (context) => const Sell()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 차량 등록 실패: ${responseData.body}')),
        );
      }
    } catch (e) {
      print("❌ [예외 발생]: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ 오류 발생: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false; // ✅ 로딩 종료
      });
    }
  }

  Widget _buildInputField() {
    if (dropdownOptions.containsKey(fields[_currentStep])) {
      final currentValue = _controller.text;
      final options = dropdownOptions[fields[_currentStep]]!;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _isCustomInput ? null : (options.contains(currentValue) ? currentValue : null),
            hint: Text("${fields[_currentStep]} 선택", style: TextStyle(color: Colors.grey[500])),
            dropdownColor: Colors.white,
            onChanged: (String? newValue) {
              setState(() {
                _isCustomInput = newValue == "직접 입력";
                if (!_isCustomInput && newValue != null) {
                  _controller.text = newValue;
                }
              });
            },
            items: options.map((String option) {
              return DropdownMenuItem<String>(value: option, child: Text(option));
            }).toList(),
          ),
          if (_isCustomInput)
            TextField(
              controller: _customInputController,
              decoration: const InputDecoration(
                hintText: "직접 입력",
                border: OutlineInputBorder(),
              ),
            ),
        ],
      );
    }

    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: "${fields[_currentStep]} 입력",
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        if (_imageFile != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(File(_imageFile!.path), height: 200),
          )
        else
          const Text('이미지를 선택해주세요'),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library, color: Colors.black),
              label: const Text('갤러리', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            ),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt, color: Colors.black),
              label: const Text('카메라', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('차량 정보 입력'), backgroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_currentStep + 1) / (fields.length + 1),
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 30),
            if (_currentStep < fields.length) ...[
              Text(
                fields[_currentStep],
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildInputField(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _prevStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text("이전"),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 10),
                  if (_currentStep < fields.length)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("다음"),
                      ),
                    ),
                ],
              ),
            ] else ...[
              _buildImagePreview(),
              const SizedBox(height: 20),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator()) // ✅ 등록 중이면 인디케이터
                  : ElevatedButton(
                      onPressed: _uploadCarInfo,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: const Text("등록 완료", style: TextStyle(color: Colors.white)),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
