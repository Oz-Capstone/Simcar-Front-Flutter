import 'package:app/buy/buy_car.dart';
import 'package:app/mypage/mypage.dart';
import 'package:flutter/material.dart';
import 'package:app/sell/home.dart';
// import 'mypage/mypage.dart';
// import 'main/home.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  static final List<Widget> _widgetOptions = <Widget>[
    const CarPurchasePage(), // 내차사기(메인페이지)
    const Sell(), // 내차팔기(sell)
    const MyPage(), //마이페이지
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text(
        'SimCar',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color:Colors.blue,
          ),
        ),
        backgroundColor: Colors.white, // ✅ 앱바 배경색 흰색
        iconTheme: const IconThemeData(color: Colors.blue), // ✅ 아이콘 색상 변경
        centerTitle: true, // ✅ 타이틀 가운데 정렬
        elevation: 2, // 앱바 구분
      ),
      
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.car_rental), label: '내 차 사기'),
          BottomNavigationBarItem(icon: Icon(Icons.sell), label: '내 차 팔기'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue, // ✅ 선택된 아이템 색상
        unselectedItemColor: Colors.grey, // ✅ 선택되지 않은 아이템 색상
        onTap: _onItemTapped,
        elevation: 2,
      ),
    );
  }
}
