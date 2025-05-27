import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class EkimYapPage extends StatefulWidget {
  const EkimYapPage({Key? key}) : super(key: key);

  @override
  _EkimYapPageState createState() => _EkimYapPageState();
}

class _EkimYapPageState extends State<EkimYapPage> {
  List<dynamic> lands = [];
  List<dynamic> categories = [];
  List<dynamic> plants = [];
  bool isLoading = true;
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

  Future<void> _submitSowing() async {
    if (_plantingAmountController.text.isEmpty ||
        _selectedDate == null ||
        _selectedLandId == null ||
        _selectedPlantId == null ||
        _selectedCategoryId == null ||
        userId == null) {
      _showSnackbar('Tüm alanları doldurmanız gerekmektedir.', Colors.red);
      return;
    }

    final url = Uri.parse('http://10.0.2.2:8080/api/sowings');
    final body = json.encode({
      "landId": _selectedLandId,
      "plantId": _selectedPlantId,
      "plantingAmount": int.parse(_plantingAmountController.text),
      "sowingDate": _selectedDate?.toIso8601String(),
      "categoryId": _selectedCategoryId,
      "categoryName": categories.firstWhere((c) => c['id'] == _selectedCategoryId)['categoryName'],
      "userId": userId,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 201) {
        _showSnackbar('Ekim başarıyla kaydedildi!', Colors.green);
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
                              ? Image.network(imageUrl, width: 30, height: 30, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
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
                onChanged: (val) => setState(() => _selectedLandId = val),
              ),
              const SizedBox(height: 16),
              _buildDropdown<int>(
                label: 'Kategori Seç',
                value: _selectedCategoryId,
                items: categories.map((cat) {
                  return DropdownMenuItem<int>(
                    value: cat['id'],
                    child: Text(cat['categoryName']),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryId = val;
                    _selectedPlantId = null;
                    plants.clear();
                  });
                  if (val != null) _fetchPlantsByCategory(val);
                },
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _plantingAmountController,
                decoration: const InputDecoration(
                  labelText: 'Ekim Miktarı',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDate == null
                        ? 'Tarih Seçilmedi'
                        : 'Seçilen Tarih: ${_selectedDate!.toLocal()}'.split(' ')[0],
                    style: GoogleFonts.notoSans(),
                  ),
                  ElevatedButton(
                    onPressed: () => _pickDate(context),
                    child: const Text('Tarih Seç'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitSowing,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Ekim Yap'),
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
    return DropdownButtonFormField<T>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      value: value,
      items: items,
      onChanged: onChanged,
    );
  }
}
