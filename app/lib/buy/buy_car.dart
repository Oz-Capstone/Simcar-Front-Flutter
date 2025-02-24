import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'buy_detail_car.dart';
import '../services/cookie_service.dart';

class CarPurchasePage extends StatefulWidget {
  const CarPurchasePage({super.key});

  @override
  _CarPurchasePageState createState() => _CarPurchasePageState();
}

class _CarPurchasePageState extends State<CarPurchasePage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> cars = []; // 최종 차량 리스트
  List<int> carIds = []; // 모든 차량 ID 리스트
  Map<int, bool> favoriteStatus = {}; // 찜 상태 저장
  Map<String, dynamic>? userInfo; // 사용자 정보 저장
  String? userPhoneNumber; // 현재 사용자 전화번호
  String baseUrl = "http://54.180.92.197:8080";
  

  @override
  void initState() {
    super.initState();
    _fetchUser(); // 사용자 정보 불러오기
  }

  /// ✅ 사용자 정보 불러오기
  Future<void> _fetchUser() async {

    try {
      final response = await http.get(
        Uri.parse("http://54.180.92.197:8080/api/members/profile"),
        headers: await ApiService.getHeaders(),
      );

      print("🔍 [프로필 조회 응답]: ${response.statusCode}");
      print("📝 [프로필 조회 본문]: ${response.body}");

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          userInfo = data;
          userPhoneNumber = data['phoneNumber']; // 사용자 전화번호 저장
        });

        _fetchCars(); // 사용자 정보를 불러온 후 차량 목록 가져오기
        _fetchFavoriteCars(); // 찜한 차량 목록 불러오기
      } else {
        throw Exception('사용자 정보를 불러오지 못했습니다.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
  }

  /// ✅ 차량 ID 목록 불러오기
  Future<void> _fetchCars() async {
    try {
      final response = await http.get(
        Uri.parse("http://54.180.92.197:8080/api/cars"),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> allCars = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          carIds = allCars.map<int>((car) => car['id'] as int).toList();
        });

        print("🔍 전체 차량 데이터: $allCars"); // ✅ 차량 리스트 출력하여 `imageUrl` 확인

        _fetchCarDetails(); // 차량 세부 정보 조회
      } else {
        throw Exception('차량 정보를 불러오지 못했습니다.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
  }

  /// ✅ 각 차량 세부 정보 조회 (전화번호 필터링)
  Future<void> _fetchCarDetails() async {
    List<Map<String, dynamic>> filteredCars = [];

    for (int carId in carIds) {
      try {
        final response = await http.get(
          Uri.parse("http://54.180.92.197:8080/api/cars/$carId"),
          headers: await ApiService.getHeaders(),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> carData = jsonDecode(utf8.decode(response.bodyBytes));

          if (carData['contactNumber'] != userPhoneNumber) {
            filteredCars.add(carData);
            print("필터링된 차량 데이터: $filteredCars"); // ✅ 필터링된 차량 데이터 출력
          }
        } else {
          throw Exception('차량 세부 정보를 불러오지 못했습니다.');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('네트워크 오류: $e')),
        );
      }
    }

    setState(() {
      cars = filteredCars;
      print("최종 차량 리스트: $cars"); // ✅ 최종 차량 리스트 출력
    });
  }

  /// ✅ 찜한 차량 목록 불러오기
  Future<void> _fetchFavoriteCars() async {
    try {
      final response = await http.get(
        Uri.parse("http://54.180.92.197:8080/api/members/favorites"),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> favoriteCars = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          for (var car in favoriteCars) {
            favoriteStatus[car['id']] = true;
          }
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

  /// ✅ 찜하기/찜 취소 기능 (서버와 동기화)
  Future<void> toggleFavorite(int carId) async {
    bool isCurrentlyFavorite = favoriteStatus[carId] ?? false;
    String apiUrl = "http://54.180.92.197:8080/api/favorites/$carId";

    try {
      final response = await (isCurrentlyFavorite
          ? http.delete(Uri.parse(apiUrl), 
          headers: await ApiService.getHeaders(),)
          : http.post(Uri.parse(apiUrl), 
          headers: await ApiService.getHeaders(),));

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          favoriteStatus[carId] = !isCurrentlyFavorite;
        });
      } else {
        throw Exception('찜하기 상태 변경 실패');
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
        title: const Text(
          '내차사기',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white, // ✅ 앱바도 흰색으로 변경
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /// 🔍 검색 바
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '어떤 차를 찾고 있나요?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),

            /// 🚗 차량 리스트
            Expanded(
              child: cars.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Colors.blue)) // ✅ 로딩 중일 때 표시
              : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: cars.length,
                itemBuilder: (context, index) {
                  var car = cars[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CarDetailPage(car: car),
                        ),
                      );
                    },
                    child: Card(
                      color: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// 차량 이미지 & 찜 버튼
                          Stack(
                            children: [
                              Image.network(
                                 car['images'][0]['filePath'].startsWith('/uploads')  // ✅ 상대경로인지 확인 후 변환
                                     ? "$baseUrl${car['images'][0]['filePath']}"      // ✅ 절대경로로 변환
                                     : car['images'][0]['filePath'],                   // ✅ 이미 절대경로면 그대로 사용
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 120,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/car.png',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 120,  // 이미지 높이 조정 
                                  );
                                },
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => toggleFavorite(car['id']),
                                  child: Icon(
                                    favoriteStatus[car['id']] ?? false
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: favoriteStatus[car['id']] ?? false
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          /// 차량 정보
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${car['brand']} ${car['model']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text('${car['year']}년식',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 14)),
                                Text('${(car['price'] / 10000).toInt()}만원',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
