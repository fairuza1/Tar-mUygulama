import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
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
        final decodedResponse = utf8.decode(response.bodyBytes); // UTF-8 ile çözümleme
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
        _showSnackbar(
            'Araziler yüklenemedi. Durum Kodu: ${response.statusCode}', Colors.red);
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
        _showSnackbar(
            'Arazi silinemedi. Durum Kodu: ${response.statusCode}', Colors.red);
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
          style: GoogleFonts.notoSans(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      )
          : ListView.builder(
        itemCount: lands.length,
        itemBuilder: (context, index) {
          final land = lands[index];
          // Check if photoPath is null or empty, if so, use default image
          String imageUrl = land['photoPath'] != null && land['photoPath'] != ''
              ? 'http://10.0.2.2:8080/lands/photo/${land['photoPath']}'
              : 'https://via.placeholder.com/150'; // Default image URL

          return Card(
            margin: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                land['name'] ?? 'Bilinmeyen Arazi',
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              subtitle: Text(
                '${land['city'] ?? 'Bilinmeyen Şehir'} - ${land['district'] ?? 'Bilinmeyen İlçe'} - ${land['village'] ?? 'Bilinmeyen Mahalle'}\n'
                    'Arazi Büyüklüğü: ${land['landSize'] ?? 'Bilinmeyen'} hektar',
                style: GoogleFonts.notoSans(fontSize: 14),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
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
            ),
          );
        },
      ),
    );
  }
}
