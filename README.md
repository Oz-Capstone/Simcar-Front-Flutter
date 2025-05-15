![image](https://github.com/user-attachments/assets/3436dc40-9a9e-4379-a6bd-6fe42356e2b8)# 🚗 SimCar - 중고차 거래 앱

Flutter 기반 중고차 매매 앱입니다.  
(서버: https://simcar.kro.kr)

## 주요 기능
- 🔑 회원가입/로그인 (세션 쿠키 관리)
- 🛒 내 차 사기 (검색, 필터, 찜 기능)
- 🚙 내 차 팔기 (차량 등록, 수정, 삭제)
- 🧑 마이페이지 (내 정보 수정, 찜 목록 관리, 회원탈퇴)

## 프로젝트 구조
```
lib/
 ├── buy/         # 차량 구매
 ├── sell/        # 차량 판매
 ├── login/       # 로그인/회원가입
 ├── mypage/      # 마이페이지
 ├── services/    # API, 세션 관리
 └── main.dart    # 앱 시작점
```

## 실행 방법
```bash
git clone https://github.com/Oz-Capstone/Simcar-Front-Flutter.git
flutter pub get
flutter run
```

## 기술 스택
- Flutter 3.x
- Dart
- SharedPreferences
- HTTP 통신
- Image Picker

## 다운로드
![image](https://github.com/user-attachments/assets/94e5e708-f260-4c2e-8d69-628d27df2222)

---

MIT License
