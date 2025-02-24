import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/cookie_service.dart';

class CarEditPage extends StatefulWidget {
  final Map<String, dynamic> car;
  const CarEditPage({super.key, required this.car});

  @override
  _CarEditPageState createState() => _CarEditPageState();
}

class _CarEditPageState extends State<CarEditPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController typeController;
  late TextEditingController priceController;
  late TextEditingController brandController;
  late TextEditingController modelController;
  late TextEditingController yearController;
  late TextEditingController mileageController;
  late TextEditingController fuelTypeController;
  late TextEditingController carNumberController;
  late TextEditingController insuranceHistoryController;
  late TextEditingController inspectionHistoryController;
  late TextEditingController colorController;
  late TextEditingController transmissionController;
  late TextEditingController regionController;
  late TextEditingController contactNumberController;

  @override
  void initState() {
    super.initState();

    typeController = TextEditingController(text: widget.car['type']);
    priceController = TextEditingController(text: widget.car['price'].toString());
    brandController = TextEditingController(text: widget.car['brand']);
    modelController = TextEditingController(text: widget.car['model']);
    yearController = TextEditingController(text: widget.car['year'].toString());
    mileageController = TextEditingController(text: widget.car['mileage'].toString());
    fuelTypeController = TextEditingController(text: widget.car['fuelType']);
    carNumberController = TextEditingController(text: widget.car['carNumber']);
    insuranceHistoryController = TextEditingController(text: widget.car['insuranceHistory'].toString());
    inspectionHistoryController = TextEditingController(text: widget.car['inspectionHistory'].toString());
    colorController = TextEditingController(text: widget.car['color']);
    transmissionController = TextEditingController(text: widget.car['transmission']);
    regionController = TextEditingController(text: widget.car['region']);
    contactNumberController = TextEditingController(text: widget.car['contactNumber']);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    Map<String, dynamic> updatedCar = {
      "type": typeController.text.trim(),
      "price": int.tryParse(priceController.text) ?? widget.car['price'],
      "brand": brandController.text.trim(),
      "model": modelController.text.trim(),
      "year": int.tryParse(yearController.text) ?? widget.car['year'],
      "mileage": int.tryParse(mileageController.text) ?? widget.car['mileage'],
      "fuelType": fuelTypeController.text.trim(),
      "imageUrl": widget.car['imageUrl'],
      "carNumber": carNumberController.text.trim(),
      "insuranceHistory": int.tryParse(insuranceHistoryController.text) ?? widget.car['insuranceHistory'],
      "inspectionHistory": int.tryParse(inspectionHistoryController.text) ?? widget.car['inspectionHistory'],
      "color": colorController.text.trim(),
      "transmission": transmissionController.text.trim(),
      "region": regionController.text.trim(),
      "contactNumber": contactNumberController.text.trim(),
    };

    try {
      final response = await http.put(
        Uri.parse("http://54.180.92.197:8080/api/cars/${widget.car['id']}"),
        headers: await ApiService.getHeaders(),
        body: jsonEncode(updatedCar),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('차량 정보가 수정되었습니다.')),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('수정 실패');
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
      appBar: AppBar(title: const Text("차량 정보 수정")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("기본 차량 정보", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                _buildTextField("차량 종류", typeController),
                _buildTextField("가격 (원)", priceController, isNumber: true),
                _buildTextField("브랜드", brandController),
                _buildTextField("모델", modelController),
                _buildTextField("연식", yearController, isNumber: true),
                _buildTextField("주행거리 (km)", mileageController, isNumber: true),
                _buildTextField("연료 타입", fuelTypeController),
                _buildTextField("차량 번호", carNumberController),

                const SizedBox(height: 20),
                const Text("추가 정보", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                _buildTextField("보험 이력", insuranceHistoryController, isNumber: true),
                _buildTextField("검사 이력", inspectionHistoryController, isNumber: true),
                _buildTextField("색상", colorController),
                _buildTextField("변속기", transmissionController),
                _buildTextField("지역", regionController),
                _buildTextField("판매자 연락처", contactNumberController),

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
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('수정'),
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

  /// 📌 마이페이지 스타일의 입력 필드 생성
  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
