import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'EkimlerDashboardPage.dart'; // EkimlerDashboardPage import edildi

class EkimYapPage extends StatefulWidget {
  const EkimYapPage({Key? key}) : super(key: key);

  @override
  _EkimYapPageState createState() => _EkimYapPageState();
}

class _EkimYapPageState extends State<EkimYapPage> {
  List<dynamic> lands = [];
  List<dynamic> categories = [];
  List<dynamic> plants = [];
  List<dynamic> suggestions = [];

  bool isLoading = true;
  bool isLoadingSuggestions = false;

  final TextEditingController _plantingAmountController = TextEditingController();
  DateTime? _selectedDate;
  int? _selectedLandId;
  int? _selectedCategoryId;
  int? _selectedPlantId;
  int? userId;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  Future<void> _fetchUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('userId');
    setState(() => userId = id);
    if (id != null) {
      await _fetchLands();
      await _fetchCategories();
    } else {
      _showSnackbar('Kullanıcı bilgileri bulunamadı.', Colors.red);
    }
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    _plantingAmountController.dispose();
    super.dispose();
  }

  Future<void> _fetchLands() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/lands?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        setState(() => lands = json.decode(decoded));
      } else {
        _showSnackbar('Araziler yüklenemedi. Kod: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Hata: $e', Colors.red);
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/categories'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        setState(() => categories = json.decode(decoded));
      } else {
        _showSnackbar('Kategoriler yüklenemedi. Kod: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Hata: $e', Colors.red);
    }
  }

  Future<void> _fetchPlantsByCategory(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/plants/by-category?categoryId=$categoryId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        setState(() => plants = json.decode(decoded));
      } else {
        _showSnackbar('Bitkiler yüklenemedi. Kod: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Hata: $e', Colors.red);
    }
  }

  Future<void> _fetchSuggestionsForLand(int landId) async {
    setState(() {
      isLoadingSuggestions = true;
      suggestions = [];
    });

    final selectedLand = lands.firstWhere((land) => land['id'] == landId, orElse: () => null);
    if (selectedLand == null) {
      _showSnackbar('Seçilen arazi bilgisi bulunamadı.', Colors.red);
      setState(() => isLoadingSuggestions = false);
      return;
    }

    final city = selectedLand['city'] ?? '';
    final district = selectedLand['district'] ?? '';
    final village = selectedLand['village'] ?? '';

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/ratings/recommendations?city=$city&district=$district&village=$village'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(decoded);

        setState(() {
          suggestions = data;
          isLoadingSuggestions = false;
        });
      } else {
        _showSnackbar('Öneriler yüklenemedi. Kod: ${response.statusCode}', Colors.red);
        setState(() => isLoadingSuggestions = false);
      }
    } catch (e) {
      _showSnackbar('Öneri alınırken hata: $e', Colors.red);
      setState(() => isLoadingSuggestions = false);
    }
  }

  Future<void> _submitSowing({bool navigate = false}) async {
    if (_plantingAmountController.text.isEmpty ||
        _selectedDate == null ||
        _selectedLandId == null ||
        _selectedPlantId == null ||
        _selectedCategoryId == null ||
        userId == null) {
      _showSnackbar('Tüm alanları doldurmanız gerekmektedir.', Colors.red);
      return;
    }

    final selectedLand = lands.firstWhere((land) => land['id'] == _selectedLandId, orElse: () => null);
    if (selectedLand == null) {
      _showSnackbar('Seçilen arazi bilgisi bulunamadı.', Colors.red);
      return;
    }

    final city = selectedLand['city'] ?? '';
    final district = selectedLand['district'] ?? '';
    final village = selectedLand['village'] ?? '';

    final url = Uri.parse('http://10.0.2.2:8080/api/sowings');
    final body = json.encode({
      "landId": _selectedLandId,
      "plantId": _selectedPlantId,
      "plantingAmount": int.parse(_plantingAmountController.text),
      "sowingDate": _selectedDate?.toIso8601String(),
      "categoryId": _selectedCategoryId,
      "categoryName": categories.firstWhere((c) => c['id'] == _selectedCategoryId)['categoryName'],
      "userId": userId,
      "city": city,
      "district": district,
      "village": village,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 201) {
        _showSnackbar('Ekim başarıyla kaydedildi!', Colors.green);
        if (navigate) {
          // Yönlendirme yapılacaksa
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => EkimlerDashboardPage()),
          );
        }
      } else {
        final decoded = json.decode(response.body);
        _showSnackbar(decoded['error'] ?? 'Bilinmeyen bir hata oluştu.', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Bir hata oluştu: $e', Colors.red);
    }
  }

  void _showSnackbar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('Ekim Yap', style: GoogleFonts.notoSans()),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : lands.isEmpty
          ? Center(child: Text('Hiç arazi bulunamadı.', style: GoogleFonts.notoSans(fontSize: 16)))
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildDropdown<int>(
                label: 'Arazi Seç',
                value: _selectedLandId,
                items: lands.map((land) {
                  String? photoPath = land['photoPath'];
                  String imageUrl = (photoPath != null && photoPath.isNotEmpty)
                      ? 'http://10.0.2.2:8080/lands/photo/$photoPath'
                      : '';
                  return DropdownMenuItem<int>(
                    value: land['id'],
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: imageUrl.isNotEmpty
                              ? Image.network(imageUrl,
                              width: 30,
                              height: 30,
                              fit: BoxFit.cover, errorBuilder: (_, __, ___) {
                                return Image.asset('assets/images/DefaultImage.jpg',
                                    width: 30, height: 30);
                              })
                              : Image.asset('assets/images/DefaultImage.jpg',
                              width: 30, height: 30),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(land['name'] ?? '', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) async {
                  setState(() {
                    _selectedLandId = val;
                    suggestions = [];
                  });
                  if (val != null) {
                    await _fetchSuggestionsForLand(val);
                  }
                },
              ),
              const SizedBox(height: 10),

              if (isLoadingSuggestions)
                const Center(child: CircularProgressIndicator())
              else if (suggestions.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Öneriler', style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...suggestions.map((item) {
                        final plantName = item['plantName'] ?? 'Bilinmeyen bitki';
                        final avgScore = item['totalScore'] != null
                            ? (item['totalScore'] * 20).toStringAsFixed(2)
                            : '-';
                        final yieldPerSquareMeter = item['yieldPerSquareMeter']?.toStringAsFixed(2) ?? '-';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(plantName, style: GoogleFonts.notoSans(fontSize: 16)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('başarı oranı %: $avgScore', style: GoogleFonts.notoSans(fontSize: 14)),
                                  Text('metrekare başına düşen: $yieldPerSquareMeter', style: GoogleFonts.notoSans(fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

              _buildDropdown<int>(
                label: 'Kategori Seç',
                value: _selectedCategoryId,
                items: categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category['id'],
                    child: Text(category['categoryName']),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryId = val;
                    plants = [];
                    _selectedPlantId = null;
                  });
                  if (val != null) _fetchPlantsByCategory(val);
                },
              ),

              const SizedBox(height: 10),

              _buildDropdown<int>(
                label: 'Bitki Seç',
                value: _selectedPlantId,
                items: plants.map((plant) {
                  final name = plant['name']?.toLowerCase() ?? '';
                  final imgPath = 'assets/images/$name.jpg';
                  return DropdownMenuItem<int>(
                    value: plant['id'],
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            imgPath,
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return Image.asset('assets/images/DefaultImage.jpg',
                                  width: 30, height: 30);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(plant['name'] ?? '', overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedPlantId = val),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _plantingAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ekim Miktarı',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: Text(
                        _selectedDate == null
                            ? 'Ekim Tarihi Seçiniz'
                            : 'Seçilen Tarih: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                        style: GoogleFonts.notoSans(fontSize: 16)),
                  ),
                  TextButton(
                    onPressed: () => _pickDate(context),
                    child: const Text('Tarih Seç'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () => _submitSowing(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Ekim Yapmaya devam et', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _submitSowing(navigate: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Ekim Yap ve ilerle', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.notoSans(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey),
          ),
          child: DropdownButton<T>(
            isExpanded: true,
            underline: const SizedBox(),
            value: value,
            items: items,
            onChanged: onChanged,
            hint: Text('Seçiniz'),
          ),
        ),
      ],
    );
  }
}
