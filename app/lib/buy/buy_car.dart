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

class _CarPurchasePageState extends State<CarPurchasePage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> allCars = [];
  List<Map<String, dynamic>> cars = [];
  List<int> carIds = [];
  Map<int, bool> favoriteStatus = {};
  String? userPhoneNumber;
  String baseUrl = "https://simcar.kro.kr";

  RangeValues _priceRange = const RangeValues(0, 10000);
  RangeValues _yearRange = const RangeValues(2000, 2024);
  List<String> _selectedBrands = [];
  List<String> _selectedFuels = [];
  String _sortOption = '최신순';

  List<String> _brandList = ['현대', '기아', 'BMW', '벤츠'];
  List<String> _fuelList = ['가솔린', '디젤', '하이브리드', '전기'];

  bool showFilterOptions = false;
  bool isLoading = true;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _fetchUser();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchUser() async {
    try {
      final response = await http.get(
        Uri.parse("https://simcar.kro.kr/api/members/profile"),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          userPhoneNumber = data['phoneNumber'];
        });
        await _fetchCars();
        await _fetchFavoriteCars();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchCars() async {
    try {
      final response = await http.get(
        Uri.parse("https://simcar.kro.kr/api/cars"),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> carList = jsonDecode(utf8.decode(response.bodyBytes));
        carIds = carList.map<int>((car) => car['id'] as int).toList();
        await _fetchCarDetails();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
  }

  Future<void> _fetchCarDetails() async {
    List<Map<String, dynamic>> filteredCars = [];
    for (int id in carIds) {
      try {
        final response = await http.get(
          Uri.parse("https://simcar.kro.kr/api/cars/$id"),
          headers: await ApiService.getHeaders(),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> car = jsonDecode(utf8.decode(response.bodyBytes));
          if (car['contactNumber'] != userPhoneNumber) {
            filteredCars.add(car);
          }
        }
      } catch (_) {}
    }
    setState(() {
      allCars = filteredCars;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    final minPrice = _priceRange.start * 10000;
    final maxPrice = _priceRange.end * 10000;
    final minYear = _yearRange.start.toInt();
    final maxYear = _yearRange.end.toInt();

    List<Map<String, dynamic>> filtered = allCars.where((car) {
      final brand = car['brand']?.toString() ?? '';
      final model = car['model']?.toString() ?? '';
      final fuel = car['fuelType']?.toString() ?? '';
      final price = car['price'] ?? 0;
      final year = car['year'] ?? 0;

      final matchesKeyword = brand.toLowerCase().contains(query) || model.toLowerCase().contains(query);
      final matchesPrice = price >= minPrice && price <= maxPrice;
      final matchesYear = year >= minYear && year <= maxYear;
      final matchesBrand = _selectedBrands.isEmpty || _selectedBrands.contains(brand);
      final matchesFuel = _selectedFuels.isEmpty || _selectedFuels.contains(fuel);

      return matchesKeyword && matchesPrice && matchesYear && matchesBrand && matchesFuel;
    }).toList();

    if (_sortOption == '가격낮은순') {
      filtered.sort((a, b) => a['price'].compareTo(b['price']));
    } else if (_sortOption == '가격높은순') {
      filtered.sort((a, b) => b['price'].compareTo(a['price']));
    } else if (_sortOption == '최신순') {
      filtered.sort((a, b) => b['year'].compareTo(a['year']));
    }

    setState(() {
      cars = filtered;
    });
  }

  void _resetFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 10000);
      _yearRange = const RangeValues(2000, 2024);
      _selectedBrands.clear();
      _selectedFuels.clear();
      _sortOption = '최신순';
    });
    _applyFilters();
  }

  Future<void> _fetchFavoriteCars() async {
    try {
      final response = await http.get(
        Uri.parse("https://simcar.kro.kr/api/members/favorites"),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> favorites = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          for (var car in favorites) {
            favoriteStatus[car['id']] = true;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
  }

  Future<void> toggleFavorite(int carId) async {
    bool isFav = favoriteStatus[carId] ?? false;
    String url = "https://simcar.kro.kr/api/favorites/$carId";

    try {
      final response = await (isFav
          ? http.delete(Uri.parse(url), headers: await ApiService.getHeaders())
          : http.post(Uri.parse(url), headers: await ApiService.getHeaders()));

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => favoriteStatus[carId] = !isFav);
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
        title: const Text('내차사기', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '어떤 차를 찾고 있나요?',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0)),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.filter_alt_outlined, color: Colors.blue),
                  onPressed: () {
                    setState(() {
                      showFilterOptions = !showFilterOptions;
                      showFilterOptions ? _controller.forward() : _controller.reverse();
                    });
                  },
                ),
              ],
            ),

            SizeTransition(
              sizeFactor: _animation,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 400), // 👈 최대 높이 지정 (원하는 값으로 조절 가능)
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('상세 필터', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  TextButton(
                                    onPressed: _resetFilters,
                                    child: const Text('필터 초기화', style: TextStyle(color: Colors.blue)),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${_priceRange.start.toInt()}만원'),
                                  Text('${_priceRange.end.toInt()}만원'),
                                ],
                              ),
                              RangeSlider(
                                activeColor: Colors.blue,
                                values: _priceRange,
                                min: 0,
                                max: 10000,
                                divisions: 100,
                                onChanged: (values) {
                                  setState(() => _priceRange = values);
                                  _applyFilters();
                                },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${_yearRange.start.toInt()}년'),
                                  Text('${_yearRange.end.toInt()}년'),
                                ],
                              ),
                              RangeSlider(
                                activeColor: Colors.blue,
                                values: _yearRange,
                                min: 2000,
                                max: DateTime.now().year.toDouble(),
                                divisions: 24,
                                onChanged: (values) {
                                  setState(() => _yearRange = values);
                                  _applyFilters();
                                },
                              ),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('브랜드'),
                              ),
                              Wrap(
                                spacing: 10,
                                children: _brandList.map((brand) {
                                  return FilterChip(
                                    label: Text(brand),
                                    selected: _selectedBrands.contains(brand),
                                    selectedColor: Colors.blue.shade100,
                                    backgroundColor: Colors.white,
                                    onSelected: (selected) {
                                      setState(() {
                                        selected ? _selectedBrands.add(brand) : _selectedBrands.remove(brand);
                                        _applyFilters();
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('연료'),
                              ),
                              Wrap(
                                spacing: 10,
                                children: _fuelList.map((fuel) {
                                  return FilterChip(
                                    label: Text(fuel),
                                    selected: _selectedFuels.contains(fuel),
                                    selectedColor: Colors.blue.shade100,
                                    backgroundColor: Colors.white,
                                    onSelected: (selected) {
                                      setState(() {
                                        selected ? _selectedFuels.add(fuel) : _selectedFuels.remove(fuel);
                                        _applyFilters();
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Text("정렬: "),
                                  DropdownButton<String>(
                                    value: _sortOption,
                                    items: ['최신순', '가격낮은순', '가격높은순'].map((opt) {
                                      return DropdownMenuItem(
                                        value: opt,
                                        child: Text(opt),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() => _sortOption = value!);
                                      _applyFilters();
                                    },
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('검색 결과: ${cars.length}건', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                  : cars.isEmpty
                      ? const Center(child: Text('검색 결과 없음', style: TextStyle(fontSize: 16)))
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: cars.length,
                          itemBuilder: (context, index) {
                            final car = cars[index];
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        Image.network(
                                          car['images'][0]['filePath'].startsWith('/uploads')
                                              ? "$baseUrl${car['images'][0]['filePath']}"
                                              : car['images'][0]['filePath'],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 120,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Image.asset(
                                              'assets/images/car.png',
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: 120,
                                            );
                                          },
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () => toggleFavorite(car['id']),
                                            child: Icon(
                                              favoriteStatus[car['id']] ?? false ? Icons.favorite : Icons.favorite_border,
                                              color: favoriteStatus[car['id']] ?? false ? Colors.red : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${car['brand']} ${car['model']}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text('${car['year']}년식',
                                              style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                          Text('${(car['price'] / 10000).toInt()}만원',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
