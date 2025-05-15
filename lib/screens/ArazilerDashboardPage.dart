import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'AraziEklePage.dart';
import 'ArazilerimiGosterPage.dart';

class ArazilerDashboardPage extends StatelessWidget {
  const ArazilerDashboardPage({Key? key}) : super(key: key);

  Future<int> fetchTotalLandCount() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/lands/count'));
    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception('Toplam arazi sayısı alınamadı');
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
                    'Arazilerim Paneli',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<int>(
                    future: fetchTotalLandCount(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(color: Colors.white);
                      } else if (snapshot.hasError) {
                        return Text('Hata oluştu', style: const TextStyle(color: Colors.white));
                      } else {
                        return Text(
                          'Toplam Arazi Sayısı: ${snapshot.data}',
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
                      _buildActionButton(context, Icons.add_location_alt, "Arazi Ekle", const AraziEklePage()),
                      _buildActionButton(context, Icons.map, "Arazilerimi Görüntüle", const ArazilerimiGosterPage()),
                    ],
                  ),
                ],
              ),
            ),

            // Açıklama
            const Expanded(
              child: Center(
                child: Text(
                  'Arazilerinizi ekleyebilir, görüntüleyebilir, güncelleyebilir veya silebilirsiniz.',
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
