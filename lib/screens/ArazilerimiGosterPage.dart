// ... diğer importlar
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'UpdateLandPage.dart';

class ArazilerimiGosterPage extends StatefulWidget {
  const ArazilerimiGosterPage({Key? key}) : super(key: key);

  @override
  _ArazilerimiGosterPageState createState() => _ArazilerimiGosterPageState();
}

class _ArazilerimiGosterPageState extends State<ArazilerimiGosterPage> {
  List<dynamic> lands = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLands();
  }

  Future<void> _fetchLands() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      _showSnackbar('Kullanıcı bilgileri bulunamadı.', Colors.red);
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
    }
  }

  Future<void> _deleteLand(int landId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8080/lands/$landId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          lands.removeWhere((land) => land['id'] == landId);
        });
        _showSnackbar('Arazi başarıyla silindi.', Colors.green);
      } else {
        _showSnackbar('Arazi silinemedi. Durum Kodu: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Silme sırasında hata oluştu: $e', Colors.red);
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

  Widget buildLandSizeCircleIndicator(double landSize) {
    double percent = (landSize / 100).clamp(0.0, 1.0);
    return CircularPercentIndicator(
      radius: 50.0,
      lineWidth: 8.0,
      animation: true,
      percent: percent,
      center: Text(
        '${landSize.toStringAsFixed(1)} ha',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
      ),
      circularStrokeCap: CircularStrokeCap.round,
      progressColor: Colors.green,
      backgroundColor: Colors.grey.shade300,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('Arazilerim', style: GoogleFonts.notoSans()),
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
          : ListView.builder(
        itemCount: lands.length,
        itemBuilder: (context, index) {
          final land = lands[index];
          String imageUrl = land['photoPath'] != null && land['photoPath'] != ''
              ? 'http://10.0.2.2:8080/lands/photo/${land['photoPath']}'
              : 'assets/images/DefaultImage.jpg';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Görsel
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageUrl.startsWith('http')
                            ? Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover)
                            : Image.asset(imageUrl, width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      // Bilgiler ve daire
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    land['name'] ?? 'Bilinmeyen Arazi',
                                    style: GoogleFonts.notoSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                UpdateLandPage(landId: land['id']),
                                          ),
                                        ).then((value) {
                                          if (value == true) {
                                            _fetchLands();
                                          }
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteLand(land['id']),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              '${land['city'] ?? 'Bilinmeyen Şehir'} - '
                                  '${land['district'] ?? 'Bilinmeyen İlçe'} - '
                                  '${land['village'] ?? 'Bilinmeyen Mahalle'}',
                              style: GoogleFonts.notoSans(fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Arazi Büyüklüğü: ${land['landSize'] ?? 'Bilinmeyen'} hektar',
                              style: GoogleFonts.notoSans(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      buildLandSizeCircleIndicator(
                        (land['landSize']?.toDouble() ?? 0.0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
