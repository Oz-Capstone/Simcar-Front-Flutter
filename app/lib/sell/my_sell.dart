import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'car_edit.dart';  // 🚀 새로 만든 차량 수정 페이지 import
import '../services/cookie_service.dart';

class MySellPage extends StatefulWidget {
  const MySellPage({super.key});

  @override
  _MySellPageState createState() => _MySellPageState();
}

class _MySellPageState extends State<MySellPage> {
  bool isloading = true; // 로딩 상태 확인
  String userPhoneNumber = "";
  List<Map<String, dynamic>> userCars = [];
  String baseUrl = "http://54.180.92.197:8080";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  /// ✅ 사용자 전화번호 가져오기
  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse("http://54.180.92.197:8080/api/members/profile"),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          userPhoneNumber = data["phone"] ?? "";
        });
        _fetchUserCars();
      } else {
        throw Exception('사용자 정보를 불러오지 못했습니다.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
  }

  /// ✅ 사용자가 등록한 차량 가져오기
  Future<void> _fetchUserCars() async {
    try {
      final response = await http.get(
        Uri.parse("http://54.180.92.197:8080/api/cars"),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> cars = jsonDecode(utf8.decode(response.bodyBytes));

        List<Map<String, dynamic>> matchedCars = [];

        for (var car in cars) {
          final carDetailResponse = await http.get(
            Uri.parse("http://54.180.92.197:8080/api/cars/${car['id']}"),
            headers: await ApiService.getHeaders(),
          );

          if (carDetailResponse.statusCode == 200) {
            final carDetail = jsonDecode(utf8.decode(carDetailResponse.bodyBytes));
            if (carDetail["contactNumber"] == userPhoneNumber) {
              matchedCars.add(carDetail);
            }
          }
        }

        setState(() {
          userCars = matchedCars;
          isloading = false; // 로딩 완료 
          print("✅ 차량 정보: $userCars");
        });
      } else {
        throw Exception('차량 정보를 불러오지 못했습니다.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
  }

  /// ✅ 차량 삭제하기 (DELETE 요청)
  Future<void> _deleteCar(int carId) async {
    try {
      final response = await http.delete(
        Uri.parse("http://54.180.92.197:8080/api/cars/$carId"),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        setState(() {
          userCars.removeWhere((car) => car['id'] == carId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('차량이 삭제되었습니다.')),
        );
      } else {
        throw Exception('차량 삭제 실패');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('판매 차량 조회'),
        backgroundColor: Colors.white, // ✅ 앱바 배경색 흰색
      ),
      body: isloading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue)) // ✅ 로딩 중 표시
          : userCars.isEmpty
          ? const Center(child: Text('등록된 차량이 없습니다.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: userCars.length,
              itemBuilder: (context, index) {
                var car = userCars[index];
                print("🚗 차량 정보: $car");
                return _buildCarItem(context, car);
              },
            ),
    );
  }

  /// ✅ 차량 카드 UI (마이페이지 UI 재사용)
  Widget _buildCarItem(BuildContext context, Map<String, dynamic> car) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Image.network(
              car['images'][0]['filePath'].startsWith('/uploads')  // ✅ 상대경로인지 확인 후 변환
                      ? "$baseUrl${car['images'][0]['filePath']}"      // ✅ 절대경로로 변환
                      : car['images'][0]['filePath'],  
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${car['brand']} ${car['model']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text('${car['year']}년식 · ${car['region']}'),
                  Text('${(car['price'] / 10000).toStringAsFixed(1)}만원'),
                ],
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CarEditPage(car: car),
                      ),
                    ).then((_) => _fetchUserCars()); // 🚀 수정 후 목록 새로고침
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('수정', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 5),
                ElevatedButton(
                  onPressed: () => _deleteCar(car['id']),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: const Text('삭제', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
