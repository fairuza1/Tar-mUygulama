import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'EkimYapPage.dart';
import 'EkimlerimiGosterPage.dart';

class EkimlerDashboardPage extends StatelessWidget {
  const EkimlerDashboardPage({Key? key}) : super(key: key);

  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId'); // Girişte kaydedilen kullanıcı ID'si
  }

  Future<double> fetchTotalCultivatedArea() async {
    final userId = await _getUserId();

    if (userId == null) {
      throw Exception("Kullanıcı ID'si bulunamadı.");
    }

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/sowings/user/$userId/total-cultivated-area'),
    );

    if (response.statusCode == 200) {
      return double.tryParse(response.body) ?? 0.0;
    } else {
      throw Exception('Toplam ekili alan alınamadı');
    }
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Widget page) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Icon(icon, color: Colors.green, size: 30),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[100],
      body: SafeArea(
        child: Column(
          children: [
            // Üst Panel
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF2E7D32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ekimler Paneli',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<double>(
                    future: fetchTotalCultivatedArea(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(color: Colors.white);
                      } else if (snapshot.hasError) {
                        return Text(
                          'Hata: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        );
                      } else {
                        return Text(
                          'Toplam Ekili Alan: ${snapshot.data!.toStringAsFixed(2)} hektar',
                          style: const TextStyle(color: Colors.white70, fontSize: 18),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  // İşlem Butonları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(context, Icons.agriculture, "Ekim Yap", const EkimYapPage()),
                      _buildActionButton(context, Icons.list_alt, "Ekimleri Göster", const EkimlerimiGosterPage()),
                    ],
                  ),
                ],
              ),
            ),

            // Açıklama veya Boş Alan
            const Expanded(
              child: Center(
                child: Text(
                  'Ekim işlemlerinizi buradan gerçekleştirebilirsiniz.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
