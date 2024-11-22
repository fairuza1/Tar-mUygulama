import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

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

  void _updateLand(int landId) {
    // Güncelleme işlemi için bir sayfaya yönlendirme (isteğe bağlı)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateLandPage(landId: landId),
      ),
    );
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
        title: Text('Arazilerim', style: GoogleFonts.notoSans()),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : lands.isEmpty
          ? Center(
        child: Text(
          'Hiçbir arazi bulunamadı.',
          style: GoogleFonts.notoSans(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      )
          : ListView.builder(
        itemCount: lands.length,
        itemBuilder: (context, index) {
          final land = lands[index];
          return Card(
            margin: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: ListTile(
              title: Text(
                land['name'] ?? 'Bilinmeyen Arazi',
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${land['city'] ?? 'Bilinmeyen Şehir'} - ${land['district'] ?? 'Bilinmeyen İlçe'}',
                style: GoogleFonts.notoSans(fontSize: 14),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _updateLand(land['id']),
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

class UpdateLandPage extends StatelessWidget {
  final int landId;

  const UpdateLandPage({Key? key, required this.landId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arazi Güncelle', style: GoogleFonts.notoSans()),
      ),
      body: Center(
        child: Text(
          'Arazi ID: $landId için güncelleme sayfası.',
          style: GoogleFonts.notoSans(fontSize: 18),
        ),
      ),
    );
  }
}
