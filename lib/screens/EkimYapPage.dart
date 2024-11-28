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
  bool isLoading = true;
  final TextEditingController _plantingAmountController = TextEditingController();
  DateTime? _selectedDate;
  int? _selectedLandId;

  @override
  void initState() {
    super.initState();
    _fetchLands();
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

  Future<void> _submitSowing() async {
    if (_plantingAmountController.text.isEmpty || _selectedDate == null || _selectedLandId == null) {
      _showSnackbar('Tüm alanları doldurmanız gerekmektedir.', Colors.red);
      return;
    }

    final url = Uri.parse('http://10.0.2.2:8080/api/sowings');
    final body = json.encode({
      "landId": _selectedLandId,
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
            // Arazi seçimi
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Arazi Seç',
                border: OutlineInputBorder(),
              ),
              items: lands.map<DropdownMenuItem<int>>((land) {
                return DropdownMenuItem<int>(
                  value: land['id'],
                  child: Text(land['name'] ?? 'Bilinmeyen Arazi'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLandId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Ekim miktarı
            TextFormField(
              controller: _plantingAmountController,
              decoration: const InputDecoration(
                labelText: 'Ekim Miktarı',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            // Tarih seçimi
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
            // Ekim yapma butonu
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
