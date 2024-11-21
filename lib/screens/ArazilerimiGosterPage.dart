import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  // Backend'den arazileri çek
  Future<void> _fetchLands() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      _showSnackbar('Kullanıcı bilgileri bulunamadı.', Colors.red);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/lands'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          lands = json.decode(response.body);
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

  // Snackbar gösterme
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
        title: const Text('Arazilerim'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : lands.isEmpty
          ? const Center(
        child: Text(
          'Hiçbir arazi bulunamadı.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: lands.length,
        itemBuilder: (context, index) {
          final land = lands[index];
          return Card(
            margin: const EdgeInsets.symmetric(
                vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              title: Text(
                land['name'] ?? 'Bilinmeyen Arazi',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${land['city'] ?? 'Bilinmeyen Şehir'} - ${land['district'] ?? 'Bilinmeyen İlçe'}',
                style: const TextStyle(fontSize: 14),
              ),
              trailing: Text(
                '${land['landSize'] ?? 0} hektar',
                style: const TextStyle(fontSize: 14),
              ),
              onTap: () {
                // Detaylar sayfasına yönlendirme (gerekirse)
              },
            ),
          );
        },
      ),
    );
  }
}
