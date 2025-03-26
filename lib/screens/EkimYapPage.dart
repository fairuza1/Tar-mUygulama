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
  int? userId;  // Kullanıcı ID'sini tutacak değişken

  @override
  void initState() {
    super.initState();
    _fetchUserId();  // Kullanıcı ID'sini al
    _fetchLands();
    _fetchCategories();
  }

  // Kullanıcı ID'sini SharedPreferences'den al
  Future<void> _fetchUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('userId');
    });
  }

  @override
  void dispose() {
    _plantingAmountController.dispose();
    super.dispose();
  }

  Future<void> _fetchLands() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      _showSnackbar('Kullanıcı bilgileri bulunamadı.', Colors.red);
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/lands?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        setState(() {
          lands = json.decode(decodedResponse);
          isLoading = false;
        });
      } else if (response.statusCode == 204) {
        setState(() {
          lands = [];
          isLoading = false;
        });
      } else {
        _showSnackbar('Araziler yüklenemedi. Durum Kodu: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Hata: $e', Colors.red);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/categories'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        setState(() {
          categories = json.decode(decodedResponse);
        });
      } else {
        _showSnackbar('Kategoriler yüklenemedi. Durum Kodu: ${response.statusCode}', Colors.red);
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
        final decodedResponse = utf8.decode(response.bodyBytes);
        setState(() {
          plants = json.decode(decodedResponse);
        });
      } else {
        _showSnackbar('Bitkiler yüklenemedi. Durum Kodu: ${response.statusCode}', Colors.red);
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
        userId == null) {
      _showSnackbar('Tüm alanları doldurmanız gerekmektedir.', Colors.red);
      return;
    }

    final url = Uri.parse('http://10.0.2.2:8080/api/sowings'); // Backend endpoint
    final body = json.encode({
      "landId": _selectedLandId,
      "plantId": _selectedPlantId,
      "plantingAmount": int.parse(_plantingAmountController.text),
      "sowingDate": _selectedDate?.toIso8601String(),
      "categoryId": _selectedCategoryId,
      "categoryName": categories.firstWhere((category) => category['id'] == _selectedCategoryId)['categoryName'],
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
        final decodedResponse = json.decode(response.body);
        final errorMessage = decodedResponse['error'] ?? 'Bilinmeyen bir hata oluştu.';
        _showSnackbar(errorMessage, Colors.red);
      }
    } catch (e) {
      _showSnackbar('Bir hata oluştu: $e', Colors.red);
    }
  }

  void _showSnackbar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
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
          ? Center(
        child: Text(
          'Hiçbir arazi bulunamadı.',
          style: GoogleFonts.notoSans(fontSize: 18, color: Colors.grey),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Arazi Seç',
                border: OutlineInputBorder(),
              ),
              value: _selectedLandId,
              items: lands.map<DropdownMenuItem<int>>((land) {
                String? photoPath = land['photoPath'];
                String imageUrl = (photoPath != null && photoPath.isNotEmpty)
                    ? 'http://10.0.2.2:8080/lands/photo/$photoPath' // Sunucudan çek
                    : ''; // Eğer boşsa, boş bırak

                return DropdownMenuItem<int>(
                  value: land['id'],
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Fazla genişlemeyi engeller
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6), // Hafif yuvarlatılmış kenarlar
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                          imageUrl,
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/DefaultImage.jpg', // Yüklenemezse assets'ten al
                              width: 30,
                              height: 30,
                            );
                          },
                        )
                            : Image.asset(
                          'assets/images/DefaultImage.jpg', // Eğer URL boşsa, direkt assets kullan
                          width: 30,
                          height: 30,
                        ),
                      ),
                      const SizedBox(width: 8), // Resim ile yazı arasında boşluk ekle
                      Flexible( // Fazla genişlemeyi engellemek için
                        child: Text(
                          land['name'] ?? 'Bilinmeyen Arazi',
                          style: GoogleFonts.notoSans(),
                          overflow: TextOverflow.ellipsis, // Taşma olursa üç nokta koy
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLandId = value;
                });
              },
            ),

            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Kategori Seç',
                border: OutlineInputBorder(),
              ),
              value: _selectedCategoryId,
              items: categories.map<DropdownMenuItem<int>>((category) {
                return DropdownMenuItem<int>(
                  value: category['id'],
                  child: Text(category['categoryName']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                  _selectedPlantId = null; // Bitki seçimini sıfırla
                  plants.clear(); // Bitki listesini temizle
                });
                if (value != null) {
                  _fetchPlantsByCategory(value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Bitki Seç',
                border: OutlineInputBorder(),
              ),
              value: _selectedPlantId,
              items: plants.map<DropdownMenuItem<int>>((plant) {
                return DropdownMenuItem<int>(
                  value: plant['id'],
                  child: Text(plant['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPlantId = value;
                });
              },
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
                ),
                ElevatedButton(
                  onPressed: () => _pickDate(context),
                  child: const Text('Tarih Seç'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _submitSowing,
                child: const Text('Ekim Yap'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
