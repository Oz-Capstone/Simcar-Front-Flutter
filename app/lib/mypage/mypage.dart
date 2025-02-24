import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit.dart';
import '../login/login.dart';
import '../buy/buy_detail_car.dart';
import '../services/cookie_service.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final int _currentPage = 1;
  final int _itemsPerPage = 3;
  String baseUrl = "http://54.180.92.197:8080";

  Map<String, dynamic> userInfo = {};
  List<Map<String, dynamic>> favoriteCars = [];

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _fetchFavoriteCars();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '마이페이지',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white, // ✅ 앱바도 흰색으로 변경
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildUserInfo(context),
              _buildFavoriteCars(context),
              _buildActionMenu(context),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 사용자 정보 가져오기
  Future<void> _fetchUserInfo() async {
    try {
      final response = await http.get(
        Uri.parse("http://54.180.92.197:8080/api/members/profile"),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        setState(() {
          userInfo = jsonDecode(utf8.decode(response.bodyBytes));
        });
      } else {
        throw Exception('사용자 정보를 불러오지 못했습니다.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
  }

  // ✅ 찜한 자동차 정보 가져오기
  Future<void> _fetchFavoriteCars() async {
    try {
      final response = await http.get(
        Uri.parse("http://54.180.92.197:8080/api/members/favorites"),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        setState(() {
          favoriteCars = List<Map<String, dynamic>>.from(
            jsonDecode(utf8.decode(response.bodyBytes)),
          );
        });
      } else {
        throw Exception('자동차 정보를 불러오지 못했습니다.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
  }

  Widget _buildUserInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.person, size: 50, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Text( // ✅ 텍스트가 넘치지 않도록 Expanded 적용
                userInfo.isNotEmpty
                    ? '${userInfo['name']} 님 반갑습니다.'
                    : '로딩 중...',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,  // ✅ 글자가 넘치면 "..."으로 표시
                maxLines: 1,  // ✅ 한 줄만 표시
              ),
          ),
                      IconButton(
          onPressed: () async {
            final updatedData = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditPage()),
            );

            // ✅ 수정된 데이터가 있을 경우 즉시 반영
            if (updatedData != null && mounted) {
              setState(() {
                userInfo['name'] = updatedData["name"];
              });
            }
          },
                icon: const Icon(Icons.edit),
              ),
            ],
          ),
    );
  }

  Widget _buildFavoriteCars(BuildContext context) {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;

    List<Map<String, dynamic>> currentCars = favoriteCars.sublist(
      startIndex,
      endIndex > favoriteCars.length ? favoriteCars.length : endIndex,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: currentCars.map((car) => _buildCarItem(context, car)).toList(),
      ),
    );
  }

  Widget _buildCarItem(BuildContext context, Map<String, dynamic> car) {
    print("🔍 car 데이터: $car"); // ✅ `car` 데이터 구조 확인
  return Card(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 16),
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CarDetailPage(car: car),
                ),
              );
            },
            child: Image.network(
              (car['imageUrl'] != null && car['imageUrl'].isNotEmpty)
                  ? "$baseUrl${car['imageUrl']}" // ✅ `imageUrl` 필드에서 직접 가져옴
                  : 'https://via.placeholder.com/80', // ✅ 기본 이미지
              width: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${car['brand']} ${car['model']}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${car['year']}년식',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                '${(car['price'] / 10000).toInt()}만원',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () => _showDeleteDialog(context, car['id']), // ✅ API 삭제 요청
          ),
        ],
      ),
    ),
  );
}

  Widget _buildActionMenu(BuildContext context) {
    return Center(
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMenu(context, '로그아웃', () => _logout(context)),
            _divider(),
            _buildMenu(context, '회원탈퇴', () => _deleteAccount(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 20,
      width: 1,
      color: Colors.grey,
    );
  }

  Future<void> _logout(BuildContext context) async {
  try {

    final response = await http.post(
      Uri.parse("$baseUrl/api/members/logout"),
      headers: await ApiService.getHeaders(),
    );

    if (response.statusCode == 200) {
      // ✅ 세션 쿠키 삭제
      await ApiService.clearSession();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃 되었습니다.')),
      );

      // ✅ 로그인 페이지로 이동
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    } else {
      throw Exception('로그아웃 실패');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('네트워크 오류: $e')),
    );
  }
}

  Future<void> _deleteAccount(BuildContext context) async {
    print("🔍 [회원탈퇴 요청]");

    final prefs = await SharedPreferences.getInstance();
    final sessionCookie = prefs.getString('session_cookie');  // ✅ JSESSIONID 가져오기
    print("✅ 저장된 세션 쿠키: $sessionCookie");
    getHeaders(); //  세션확인여부
    
    showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white, // 배경 흰색
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // 모서리 둥글게
      ),
      title: const Text(
        '회원탈퇴',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Text('정말 회원탈퇴를 진행하시겠습니까?'),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200], // 배경 회색
                  foregroundColor: Colors.black, // 글씨 빨강
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('취소'),
              ),
            ),
            const SizedBox(width: 10), // 버튼 간 간격
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final response = await http.delete( // ✅ DELETE 요청 사용
                      Uri.parse("$baseUrl/api/members/profile"),
                      headers: {
                          "Accept": "*/*",
                          "Content-Type": "application/json", // ✅ Content-Type 추가
                          "Cookie": sessionCookie ?? "", // ✅ JSESSIONID 포함
                        },
                    );

                    print("✅ [회원탈퇴 요청 전송 완료]");
                    print("🔍 [서버 응답 코드]: ${response.statusCode}");
                    print("📝 [서버 응답 본문]: ${response.body}");

                    if (response.statusCode == 200) {
                      // ✅ 세션 삭제
                      await ApiService.clearSession();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('회원탈퇴가 완료되었습니다.')),
                      );

                      // ✅ 로그인 페이지로 이동
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (Route<dynamic> route) => false,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('회원탈퇴 실패: ${response.body}')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('네트워크 오류: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // 배경 빨강
                  foregroundColor: Colors.white, // 글씨 검정
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<Map<String, String>> getHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final sessionCookie = prefs.getString('session_cookie');

  if (sessionCookie == null || sessionCookie.isEmpty) {
    print("❌ [오류] 저장된 JSESSIONID 없음");
  } else {
    print("✅ [JSESSIONID 포함]: $sessionCookie");
  }

  return {
    "Accept": "*/*",
    "Cookie": sessionCookie ?? "",
  };
}




  void _showDeleteDialog(BuildContext context, int carId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white, // 배경 흰색
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // 모서리 둥글게
      ),
      title: const Text(
        '찜 리스트에서 해당 차량을 제외하시겠습니까?',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200], // 배경 회색
                  foregroundColor: Colors.black, // 글씨 빨강
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('취소'),
              ),
            ),
            const SizedBox(width: 10), // 버튼 간 간격
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // 다이얼로그 닫기
                  await _deleteFavoriteCar(carId); // ✅ API를 통해 삭제 요청
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // 배경 빨강
                  foregroundColor: Colors.white, // 글씨 검정
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


Future<void> _deleteFavoriteCar(int carId) async {
  try {
    final response = await http.delete(
      Uri.parse("$baseUrl/api/favorites/$carId"),
      headers: await ApiService.getHeaders(),
    );

    if (response.statusCode == 200) {
      setState(() {
        favoriteCars.removeWhere((car) => car['id'] == carId); // ✅ UI에서 즉시 삭제
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('찜 목록에서 삭제되었습니다.')),
      );
    } else {
      throw Exception('찜한 차량 삭제 실패');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('네트워크 오류: $e')),
    );
  }
}
}


