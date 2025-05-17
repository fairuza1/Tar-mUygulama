import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'EkimYapPage.dart';
import 'EkimlerimiGosterPage.dart';

class EkimlerDashboardPage extends StatefulWidget {
  const EkimlerDashboardPage({Key? key}) : super(key: key);

  @override
  State<EkimlerDashboardPage> createState() => _EkimlerDashboardPageState();
}

class _EkimlerDashboardPageState extends State<EkimlerDashboardPage> {
  late Future<double> _totalAreaFuture;
  late Future<List<Map<String, dynamic>>> _recentSowingsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _totalAreaFuture = fetchTotalCultivatedArea();
    _recentSowingsFuture = fetchRecentSowings();
  }

  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Future<double> fetchTotalCultivatedArea() async {
    final userId = await _getUserId();
    if (userId == null) throw Exception("Kullanıcı ID'si bulunamadı.");

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/sowings/user/$userId/total-cultivated-area'),
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      return double.tryParse(decodedBody) ?? 0.0;
    } else {
      throw Exception('Toplam ekili alan alınamadı');
    }
  }

  Future<List<Map<String, dynamic>>> fetchRecentSowings() async {
    final userId = await _getUserId();
    if (userId == null) throw Exception("Kullanıcı ID'si bulunamadı.");

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/sowings/user/$userId/recent'),
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      List<dynamic> data = json.decode(decodedBody);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Son işlemler alınamadı');
    }
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String label, Widget page) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        setState(() {
          _loadData(); // Sayfa geri dönünce verileri yenile
        });
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        color: Colors.white,
        child: Container(
          width: 120,
          height: 120,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.green[700]),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.green[900],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSowingCard(Map<String, dynamic> sowing) {
    bool isHarvested = sowing['harvested'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: const Icon(Icons.local_florist, color: Colors.green),
        title: Text(
          sowing['plantName'],
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Tarih: ${sowing['sowingDate']}\nMiktar: ${sowing['plantingAmount']} kg',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isHarvested ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isHarvested ? Icons.trending_down : Icons.trending_up,
                color: isHarvested ? Colors.red : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                isHarvested ? "Hasat Edildi" : "Ekildi",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isHarvested ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFA5D6A7), Color(0xFF2E7D32)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ekimler Paneli',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<double>(
                      future: _totalAreaFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator(color: Colors.white);
                        } else if (snapshot.hasError) {
                          return Text(
                            'Hata: ${snapshot.error}',
                            style: const TextStyle(color: Colors.redAccent),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionCard(context, Icons.agriculture, "Ekim Yap", const EkimYapPage()),
                        _buildActionCard(context, Icons.list_alt, "Ekimleri Göster", const EkimlerimiGosterPage()),
                      ],
                    ),
                  ],
                ),
              ),
              // Son Ekimler Başlık + "..." Butonu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Son Ekimler",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz, color: Colors.white),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EkimlerimiGosterPage()),
                        );
                        setState(() {
                          _loadData(); // Geri dönünce verileri yenile
                        });
                      },
                    ),
                  ],
                ),
              ),
              // Liste
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _recentSowingsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Hata: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      } else if (snapshot.data!.isEmpty) {
                        return const Center(child: Text("Henüz ekim yapılmamış."));
                      } else {
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) =>
                              _buildRecentSowingCard(snapshot.data![index]),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
