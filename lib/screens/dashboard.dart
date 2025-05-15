import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http; // <-- EKLENDİ
import 'package:uygulamam_flutter/screens/ArazilerDashboardPage.dart';
import 'dart:convert';

import 'AraziEklePage.dart';
import 'ArazilerimiGosterPage.dart';
import 'EkimYapPage.dart';
import 'EkimlerimiGosterPage.dart';
import 'HasatlarimiGosterPage.dart';
import 'DegerlendirmelerimiListelePage.dart';
import 'OneriSayfasi.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({Key? key}) : super(key: key);

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Widget page) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => page));
          },
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(icon, color: Colors.green),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center),
      ],
    );
  }

  Future<int> fetchTotalLandCount() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/lands/count'));
    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception('Toplam arazi sayısı alınamadı');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Üst Yeşil Kısım
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF228B22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tarım Dashboard',
                    style: GoogleFonts.pacifico(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hoş geldiniz! Tarımsal işlemlerinizi buradan yönetin.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),

                  /// 🌿 Toplam Arazi Sayısı - FutureBuilder ile
                  Center(
                    child: FutureBuilder<int>(
                      future: fetchTotalLandCount(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator(color: Colors.white);
                        } else if (snapshot.hasError) {
                          return Text(
                            'Hata oluştu',
                            style: TextStyle(color: Colors.white),
                          );
                        } else {
                          return Column(
                            children: [
                              Text(
                                'Toplam Arazi Sayısı',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${snapshot.data} Arazi',
                                style: TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  // İşlem Butonları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(context, Icons.add_location_alt, "Arazi Ekle", AraziEklePage()),
                      _buildActionButton(context, Icons.map, "Arazilerim", ArazilerimiGosterPage()),
                      _buildActionButton(context, Icons.agriculture, "Ekim Yap", EkimYapPage()),
                      _buildActionButton(context, Icons.timeline, "Ekimlerim", EkimlerimiGosterPage()),
                      _buildActionButton(context, Icons.timeline, "Ekimlerim", ArazilerDashboardPage()),

                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(context, Icons.grass, "Hasatlarım", HasatlarimiGosterPage()),
                      _buildActionButton(context, Icons.list_alt, "Değerlendirmeler", DegerlendirmelerimiListelePage()),
                      _buildActionButton(context, Icons.recommend, "Öneriler", OneriSayfasi()),
                      const SizedBox(width: 48),
                    ],
                  ),
                ],
              ),
            ),

            // Alt Kısım - Son İşlemler
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Son İşlemler',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Icon(Icons.filter_list),
                ],
              ),
            ),

            // Örnek işlem kartları
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildTransactionCard(
                    color: Colors.green,
                    title: 'Ekim Yapıldı',
                    date: '14 Mayıs 2025',
                    quantity: 'Buğday - 50kg',
                    price: 'Maliyet: 1.200₺',
                  ),
                  _buildTransactionCard(
                    color: Colors.orange,
                    title: 'Hasat Yapıldı',
                    date: '12 Mayıs 2025',
                    quantity: 'Domates - 150kg',
                    price: 'Gelir: 3.400₺',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard({
    required Color color,
    required String title,
    required String date,
    required String quantity,
    required String price,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(Icons.check, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(date),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(quantity),
            Text(price),
          ],
        ),
      ),
    );
  }
}
