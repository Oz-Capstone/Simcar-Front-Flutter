import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/cookie_service.dart';
import '../services/storage_service.dart';

class CarDetailPage extends StatefulWidget {
  final Map<String, dynamic> car;

  const CarDetailPage({super.key, required this.car});

  @override
  _CarDetailPageState createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  bool isLoading = true;
  bool isFavorite = false;
  int reliabilityScore = 85;
  String evaluationComment = "사기이력이 없는 자동차에요";
  Map<String, dynamic>? carDetail;
  String baseUrl = "http://54.180.92.197:8080"; // ✅ 백엔드 URL

  @override
  void initState() {
    super.initState();
    _fetchCarDetail();
    _fetchFavoriteStatus();
    _fetchDiagnosisInfo();
  }

  Future<void> _fetchCarDetail() async {
    try {
      final response = await http.get(
        Uri.parse("http://54.180.92.197:8080/api/cars/${widget.car['id']}"),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        setState(() {
          carDetail = jsonDecode(utf8.decode(response.bodyBytes));
          isLoading = false;
          print("carDetail: $carDetail");
        });
      } else {
        throw Exception('차량 상세 정보를 불러오지 못했습니다.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchFavoriteStatus() async {
    try {
      final response = await http.get(
        Uri.parse("http://54.180.92.197:8080/api/members/favorites"),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> favoriteCars = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          isFavorite = favoriteCars.any((car) => car['id'] == widget.car['id']);
        });
      } else {
        throw Exception('찜한 차량을 불러오지 못했습니다.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
  }

  Future<void> _fetchDiagnosisInfo() async {
    try {
      final response = await http.get(
        Uri.parse("http://54.180.92.197:8080/api/cars/${widget.car['id']}/diagnosis"),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          reliabilityScore = data['reliabilityScore'] ?? 50;
          evaluationComment = data['evaluationComment'] ?? "평가 정보 없음";
        });
      } else {
        throw Exception('차량 진단 정보를 불러오지 못했습니다.');
      }
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('네트워크 오류: $e')),
      // );
    }
  }

  /// ✅ 현재 차량 데이터 (API에서 불러오지 못한 경우 기본값 사용)
  Map<String, dynamic> get _carData => carDetail ?? widget.car;

  void _showDetails() {
    if (carDetail == null) return;

    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('차량 세부정보',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildDetailRow('차량 종류', _carData['type'], Colors.grey.shade400, Colors.black),
              _buildDetailRow('가격', '${_carData['price']}원', Colors.grey.shade400, Colors.black),
              _buildDetailRow('브랜드', _carData['brand'], Colors.grey.shade400, Colors.black),
              _buildDetailRow('모델', _carData['model'], Colors.grey.shade400, Colors.black),
              _buildDetailRow('연식', '${_carData['year']}년', Colors.grey.shade400, Colors.black),
              _buildDetailRow('주행거리', '${_carData['mileage']} km', Colors.grey.shade400, Colors.black),
              _buildDetailRow('연료 타입', _carData['fuelType'], Colors.grey.shade400, Colors.black),
              _buildDetailRow('차량 번호', _carData['carNumber'], Colors.grey.shade400, Colors.black),
              _buildDetailRow('색상', _carData['color'], Colors.grey.shade400, Colors.black),
              _buildDetailRow('변속기', _carData['transmission'], Colors.grey.shade400, Colors.black),
              _buildDetailRow('판매 지역', _carData['region'], Colors.grey.shade400, Colors.black),
              _buildDetailRow('판매자 이름', _carData['sellerName'], Colors.grey.shade400, Colors.black),
              _buildDetailRow('판매자 연락처', _carData['contactNumber'], Colors.grey.shade400, Colors.black),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosisSection() {
    // Color diagnosisColor = Color.lerp(Colors.red, Colors.green, reliabilityScore / 100)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: isLoading 
      ? const Center(child: CircularProgressIndicator(color: Colors.white))
      : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Simcar AI 진단', 
            style: TextStyle(
              fontSize: 20, 
              color: Colors.white,
              fontWeight: FontWeight.bold),
              ),
          const SizedBox(height: 10),
          _buildDetailRow('안전성 점수', '$reliabilityScore 점', Colors.white, Colors.white),
          _buildDetailRow('진단 평가', evaluationComment, Colors.white, Colors.white),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, Color titleColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
        Expanded( // ✅ 제목이 너무 길어도 자동 줄바꿈
          child: Text(
            title, 
            style: TextStyle(color: titleColor, fontSize: 16),
            overflow: TextOverflow.ellipsis, // 너무 길면 "..." 처리
          ),
        ),
        const SizedBox(width: 10), // ✅ 간격 추가
        Expanded( // ✅ 값도 자동 줄바꿈
          child: Text(
            value, 
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            textAlign: TextAlign.right, // ✅ 오른쪽 정렬
            overflow: TextOverflow.visible, // 자동 줄바꿈
          ),
        ),
      ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('차량 상세'),
        backgroundColor: Colors.white, // ✅ 앱바 배경색 흰색
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0), // ✅ 왼쪽 정렬 적용
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // ✅ 전체 왼쪽 정렬
                  children: [
                    Image.network(
                       (_carData['images'] != null && _carData['images'].isNotEmpty)
                          ? "$baseUrl${_carData['images'][0]['filePath']}"
                          : 'https://via.placeholder.com/300',
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
  onTap: _showDetails,
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white, // 연한 파란색 배경
      borderRadius: BorderRadius.circular(10), // 둥근 모서리
      border: Border.all(color: Colors.blue, width: 1), // 파란색 테두리 추가
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, color: Colors.blue), // 아이콘 추가
        SizedBox(width: 8),
        Text(
          '차량 상세정보',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue, // 강조된 파란색 텍스트
          ),
        ),
      ],
    ),
  ),
),
                    const SizedBox(height: 20),
                    _buildDiagnosisSection(),
                  ],
                ),
              ),
            ),
    );
  }
}
