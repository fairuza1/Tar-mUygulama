import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AraziEklePage.dart';
import 'ArazilerimiGosterPage.dart';

class ArazilerDashboardPage extends StatefulWidget {
  const ArazilerDashboardPage({Key? key}) : super(key: key);

  @override
  State<ArazilerDashboardPage> createState() => _ArazilerDashboardPageState();
}

class _ArazilerDashboardPageState extends State<ArazilerDashboardPage> {
  late Future<int> totalLandCountFuture;
  late Future<List<Map<String, dynamic>>> last5LandsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    totalLandCountFuture = fetchTotalLandCount();
    last5LandsFuture = fetchLast5Lands();
  }

  Future<int> fetchTotalLandCount() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/lands/count'));
    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception('Toplam arazi sayısı alınamadı');
    }
  }

  Future<List<Map<String, dynamic>>> fetchLast5Lands() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      throw Exception('Kullanıcı ID\'si bulunamadı.');
    }

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/lands/last5?userId=$userId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Son 5 arazi verisi alınamadı');
    }
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Widget page) {
    return InkWell(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        setState(() {
          _refreshData(); // Sayfaya geri dönüldüğünde verileri yenile
        });
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
              color: const Color(0xFF228B22),
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
                  Center(
                    child: FutureBuilder<int>(
                      future: totalLandCountFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator(color: Colors.white);
                        } else if (snapshot.hasError) {
                          return const Text('Hata oluştu', style: TextStyle(color: Colors.white));
                        } else {
                          return Column(
                            children: [
                              const Text(
                                'Toplam Arazi Sayısı',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${snapshot.data} Arazi',
                                style: const TextStyle(
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
                  const SizedBox(height: 20),
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

            // Alt Panel: Son 5 Arazi
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Son eklenen araziler',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: last5LandsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Veriler alınamadı: ${snapshot.error}'));
                          } else if (snapshot.data!.isEmpty) {
                            return const Center(child: Text('Hiç arazi bulunamadı.'));
                          } else {
                            return ListView.builder(
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                final land = snapshot.data![index];

                                final imageUrl = land['photoPath'] != null && land['photoPath'] != ''
                                    ? 'http://10.0.2.2:8080/lands/photo/${land['photoPath']}'
                                    : 'assets/images/DefaultImage.jpg';

                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 3,
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageUrl.startsWith('http')
                                          ? Image.network(
                                        imageUrl,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.image_not_supported),
                                      )
                                          : Image.asset(
                                        imageUrl,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    title: Text(
                                      land['name'] ?? 'Bilinmeyen Arazi',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${land['city'] ?? 'Şehir bilinmiyor'} - '
                                              '${land['district'] ?? 'İlçe bilinmiyor'} - '
                                              '${land['village'] ?? 'Mahalle bilinmiyor'}',
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Büyüklük:  ${land['landSize'] ?? 'Bilinmiyor'} m²',
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
