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

  @override
  void initState() {
    super.initState();
    _fetchLands();
    _fetchCategories();
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
    if (_plantingAmountController.text.isEmpty || _selectedDate == null || _selectedLandId == null || _selectedPlantId == null) {
      _showSnackbar('Tüm alanları doldurmanız gerekmektedir.', Colors.red);
      return;
    }

    final url = Uri.parse('http://10.0.2.2:8080/api/sowings');
    final body = json.encode({
      "landId": _selectedLandId,
      "plantId": _selectedPlantId,
      "plantingAmount": int.parse(_plantingAmountController.text),
      "sowingDate": _selectedDate?.toIso8601String(),
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
        _showSnackbar('Hata oluştu! HTTP Durum Kodu: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Bir hata oluştu: $e', Colors.red);
    }
  }

  void _showSnackbar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message, style: GoogleFonts.notoSans()),
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

  void _openSowingDialog(int landId) {
    setState(() {
      _selectedLandId = landId;
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ekim Yap'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Kategori Seç',
                  border: OutlineInputBorder(),
                ),
                items: categories.map<DropdownMenuItem<int>>((category) {
                  return DropdownMenuItem<int>(
                    value: category['id'],
                    child: Text(category['categoryName'] ?? 'Bilinmeyen Kategori'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                    _selectedPlantId = null; // Yeni seçimle önceki bitkiyi sıfırla
                    plants = []; // Bitki listesini temizle
                  });
                  if (value != null) {
                    _fetchPlantsByCategory(value); // Kategorilere göre bitki çek
                  }
                },
                value: _selectedCategoryId,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Bitki Seç',
                  border: OutlineInputBorder(),
                ),
                items: plants.map<DropdownMenuItem<int>>((plant) {
                  return DropdownMenuItem<int>(
                    value: plant['id'],
                    child: Text(plant['name'] ?? 'Bilinmeyen Bitki'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPlantId = value;
                  });
                },
                value: _selectedPlantId,
                hint: const Text('Önce bir kategori seçin'),
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
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                _submitSowing();
                Navigator.of(context).pop();
              },
              child: const Text('Ekim Yap'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Arazilerim',
          style: GoogleFonts.notoSans(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: lands.length,
        itemBuilder: (context, index) {
          final land = lands[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(
                land['name'] ?? 'Bilinmeyen Arazi',
                style: GoogleFonts.notoSans(),
              ),
              subtitle: Text(
                'Ekin Durumu: ${land['status']}',
                style: GoogleFonts.notoSans(),
              ),
              onTap: () => _openSowingDialog(land['id']),
            ),
          );
        },
      ),
    );
  }
}
