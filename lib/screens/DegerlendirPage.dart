import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class DegerlendirPage extends StatefulWidget {
  final Map<String, dynamic> harvest;

  const DegerlendirPage({Key? key, required this.harvest}) : super(key: key);

  @override
  _DegerlendirPageState createState() => _DegerlendirPageState();
}

class _DegerlendirPageState extends State<DegerlendirPage> {
  final _commentController = TextEditingController();
  int? _rating;
  String _harvestStatus = 'normal'; // Varsayılan durum "normal"

  Future<void> _submitRating(BuildContext context) async {
    final url = Uri.parse('http://10.0.2.2:8080/api/ratings'); // Emülatör için localhost

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'harvestId': widget.harvest['id'],
          'rating': _rating,
          'comment': _commentController.text,
          'harvestStatus': _harvestStatus,
        }),
      );

      print("🔁 Gönderilen harvest ID: ${widget.harvest['id']}");
      print("📡 Durum Kodu: ${response.statusCode}");
      print("📥 Cevap Gövdesi: ${response.body}");

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Değerlendirme kaydedildi!')),
        );
        Navigator.pushReplacementNamed(context, '/degerlendirmeler');
      } else {
        // Hata varsa mesajı göster
        String errorMsg = 'Hata ${response.statusCode}: ${response.body}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      // Ağ veya istek atılamama durumu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ İstek atılamadı: $e')),
      );
      print("🚫 Hata oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hasat Değerlendirme', style: GoogleFonts.notoSans()),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hasat ID: ${widget.harvest['id']}\n'
                  'Bitki: ${widget.harvest['plantName']}\n'
                  'Kategori: ${widget.harvest['categoryName']}\n'
                  'Ekim Miktarı: ${widget.harvest['plantingAmount']}',
              style: GoogleFonts.notoSans(fontSize: 16),
            ),
            const SizedBox(height: 20),
            // Yorum Alanı
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Yorum (Opsiyonel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            // Puanlama Alanı
            Text('Puan:'),
            Slider(
              value: _rating?.toDouble() ?? 0,
              min: 0,
              max: 5,
              divisions: 5,
              label: _rating?.toString(),
              onChanged: (value) {
                setState(() {
                  _rating = value.toInt();
                });
              },
            ),
            const SizedBox(height: 20),
            // Hasat Durumu Seçimi
            Text('Hasat Durumu:'),
            DropdownButton<String>(
              value: _harvestStatus,
              items: <String>['çok kötü', 'kötü', 'normal', 'iyi', 'çok iyi']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _harvestStatus = newValue!;
                });
              },
            ),
            const SizedBox(height: 20),
            // Değerlendirme Gönderme Butonu
            ElevatedButton(
              onPressed: () => _submitRating(context),
              child: const Text('Değerlendir'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
