import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class DegerlendirPage extends StatelessWidget {
  final Map<String, dynamic> harvest;

  const DegerlendirPage({Key? key, required this.harvest}) : super(key: key);

  Future<void> _submitRating(BuildContext context) async {
    final url = Uri.parse('http://10.0.2.2:8080/api/ratings'); // Emülatör için localhost

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'harvestId': harvest['id']}),
      );

      print("🔁 Gönderilen harvest ID: ${harvest['id']}");
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
              'Hasat ID: ${harvest['id']}\n'
                  'Bitki: ${harvest['plantName']}\n'
                  'Kategori: ${harvest['categoryName']}\n'
                  'Ekim Miktarı: ${harvest['plantingAmount']}',
              style: GoogleFonts.notoSans(fontSize: 16),
            ),
            const SizedBox(height: 20),
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
