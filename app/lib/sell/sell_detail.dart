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
  int _currentStep = 0; // 현재 입력 단계
  XFile? _imageFile; // 이미지 파일
  final picker = ImagePicker();
  bool _isCustomInput = false;
  
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
    // 가격, 차 번호, 전화번호만 직접 입력
    "차량 종류": ["세단", "SUV", "트럭", "쿠페", "해치백", "직접 입력"],
    "브랜드": ["현대", "기아", "BMW", "벤츠", "아우디", "직접 입력"],
    "모델": ["소나타", "아반떼", "카니발", "K5", "그랜저", "직접 입력"],
    "연식" : ["2012", "2013", "2014", "2015", "2016", "직접 입력"],
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
  setState(() {
    if (_currentStep < fields.length) {
      String key = carRequest.keys.elementAt(_currentStep); // 현재 인덱스에 해당하는 key 가져오기

      if (!_isCustomInput) {
        carRequest[key] = _controller.text.isNotEmpty ? _controller.text : carRequest[key];
      } else {
        carRequest[key] = _customInputController.text.isNotEmpty ? _customInputController.text : carRequest[key];
      }

      _controller.clear();
      _customInputController.clear();
      _isCustomInput = false;
      _currentStep++;
    } else {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("이미지를 선택해주세요.")),
        );
      } else {
        _uploadCarInfo();
      }
    }
  });
}


  void _prevStep() {
  if (_currentStep > 0) {
    setState(() {
      _currentStep--;
      String key = carRequest.keys.elementAt(_currentStep);

      _controller.text = carRequest[key]?.toString() ?? "";
      if (_isCustomInput) {
        _customInputController.text = carRequest[key]?.toString() ?? "";
      }
    });
  }
}


// Future<void> checkSession() async {
//   var response = await http.get(
//     Uri.parse("http://54.180.92.197:8080/api/members/profile"),
//     headers: await ApiService.getHeaders(),
//   );

//   print("🔍 [세션 확인 응답]: ${response.statusCode}");
//   print("📝 [세션 확인 응답 본문]: ${response.body}");
// }


  Future<void> _uploadCarInfo() async {
    // checkSession();  // ✅ 세션 확인
    final prefs = await SharedPreferences.getInstance();
    final sessionCookie = prefs.getString('session_cookie');  // ✅ JSESSIONID 가져오기
    print("✅ 저장된 세션 쿠키: $sessionCookie");

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

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://54.180.92.197:8080/api/cars"),
      );

      request.headers.addAll({
        "Content-Type": "multipart/form-data",
        "Accept": "*/*",
        "Cookie": sessionCookie,  // ✅ 저장된 세션 쿠키 추가
      });

      // print("📡 [요청 전송]: ${request.url}");
      // print("📝 [요청 헤더]: ${request.headers}");

      // JSON 데이터를 application/json 타입으로 추가
    request.files.add(
      http.MultipartFile.fromString(
        'request',
        jsonEncode({
          "type": carRequest["type"],
          "price": int.parse(carRequest["price"]),
          "brand": carRequest["brand"],
          "model": carRequest["model"],
          "year": int.parse(carRequest["year"]),
          "mileage": int.parse(carRequest["mileage"]),
          "fuelType": carRequest["fuelType"],
          "carNumber": carRequest["carNumber"],
          "insuranceHistory": int.tryParse(carRequest["insuranceHistory"].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0, // ✅ 숫자만 추출 후 변환
          "inspectionHistory": int.tryParse(carRequest["inspectionHistory"].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0, // ✅ 숫자만 추출 후 변환
          "color": carRequest["color"],
          "transmission": carRequest["transmission"],
          "region": carRequest["region"],
          "contactNumber": carRequest["contactNumber"],
        }),
        contentType: MediaType('application', 'json'),
      ),
    );

    // 이미지 파일 추가
    final mimeType = lookupMimeType(_imageFile!.path) ?? 'image/png';
    final mimeSplit = mimeType.split('/');
    request.files.add(await http.MultipartFile.fromPath(
      'images',
      _imageFile!.path,
      contentType: MediaType(mimeSplit[0], mimeSplit[1]),
    ));

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      print("[request]: $request");
      print("[request.fields]: ${request.fields}");
      print("request.files: ${request.files}");

      // print("✅ [서버 응답 코드]: ${response.statusCode}");
      // print("🔍 [서버 응답 본문]: ${responseData.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🚗 차량이 성공적으로 등록되었습니다.')),
        );
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
    }
  }

  Widget _buildImagePreview() {
    if (_imageFile != null) {
      return Image.file(File(_imageFile!.path), height: 200);
    }
    return const Text('이미지를 선택해주세요');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('차량 정보 입력'),
      backgroundColor: Colors.white, // ✅ 앱바 배경색 흰색

      ),
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

              if (dropdownOptions.containsKey(fields[_currentStep])) ...[
                DropdownButtonFormField<String>(
                  value: dropdownOptions[fields[_currentStep]]!.contains(carRequest[carRequest.keys.elementAt(_currentStep)]) 
                    ? carRequest[carRequest.keys.elementAt(_currentStep)]
                    : null, // 값이 목록에 없으면 null로 설정하여 오류 방지
                        hint: Text("${fields[_currentStep]} 선택", style: TextStyle(color: Colors.grey[500])),
                        dropdownColor: Colors.white, // ✅ 드롭다운 리스트 배경색 흰색으로 변경
                        onChanged: (String? newValue) {
                        setState(() {
                          _isCustomInput = newValue == "직접 입력";
                          String key = carRequest.keys.elementAt(_currentStep);
                          carRequest[key] = newValue!;
                        });
                      },
                      items: dropdownOptions[fields[_currentStep]]!.map((String option) {
                        return DropdownMenuItem<String>(value: option, child: Text(option));
                      }).toList(),
                    ),
              ],
         if (_isCustomInput)
          TextField(
            controller: _customInputController,
            decoration: const InputDecoration(
              hintText: "직접 입력",
              border: OutlineInputBorder(),
            ),
          )
        else if (fields[_currentStep] == "가격")
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "0 ~ 9999999원 (예: 35000000)", // ✅ 가격 입력 예제 추가
              border: OutlineInputBorder(),
            ),
          )
        else if (fields[_currentStep] == "차 번호")
          TextField(
            controller: _controller,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              hintText: "12가 3456", // ✅ 차량 번호 입력 예제 추가
              border: OutlineInputBorder(),
            ),
          )
        else if (fields[_currentStep] == "전화번호")
          TextField(
            controller: _controller,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              hintText: "010-1111-2222", // ✅ 전화번호 입력 예제 추가
              border: OutlineInputBorder(),
            ),
          )
      else
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: "${fields[_currentStep]} 입력", // ✅ 기본 값 유지
            border: const OutlineInputBorder(),
          ),
        ),
      const SizedBox(height: 20), // 버튼 간격 추가
             
                        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 🔹 첫 번째 단계에서는 '이전' 버튼 숨김
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
              
              if (_currentStep > 0) const SizedBox(width: 10), // 버튼 간격 추가

              // 🔹 마지막 단계에서는 '다음' 버튼 숨김
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
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.gallery), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                child: const Text('갤러리',
                style: TextStyle(
                  color: Colors.black,
                  ),
                 ),
                ),
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.camera), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                child: const Text('카메라',
                style: TextStyle(
                  color: Colors.black,
                    ),
                  ),
                ),
               ElevatedButton(
                onPressed: () async {
                  await _uploadCarInfo(); // ✅ 함수 실행
                  Navigator.pop( 
                    context,
                     MaterialPageRoute(builder: (context) => const Sell()),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text(
                  "등록 완료",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
