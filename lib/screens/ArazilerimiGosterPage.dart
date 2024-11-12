import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class ArazilerimiGosterPage extends StatefulWidget {
  const ArazilerimiGosterPage({Key? key}) : super(key: key);

  @override
  _ArazilerimiGosterPageState createState() => _ArazilerimiGosterPageState();
}

class _ArazilerimiGosterPageState extends State<ArazilerimiGosterPage> {
  List<Map<String, dynamic>> araziler = [];

  @override
  void initState() {
    super.initState();
    _fetchAraziler();
  }

  Future<void> _fetchAraziler() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:8080/lands'));

      if (response.statusCode == 200) {
        // Eğer yanıt başarılıysa, JSON verisini çözümle
        String decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> data = json.decode(decodedBody);

        setState(() {
          araziler = data.map((item) => item as Map<String, dynamic>).toList();
        });
      } else {
        _showSnackbar('Araziler alınamadı.', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Hata: $e', Colors.red);
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
        title: const Text('Arazilerimi Göster'),
      ),
      body: araziler.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: araziler.length,
          itemBuilder: (context, index) {
            final arazi = araziler[index];
            return Card(
              elevation: 5,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      arazi['name'] ?? 'İsimsiz Arazi',
                      style: GoogleFonts.notoSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Büyüklük: ${arazi['landSize']} hektar',
                      style: GoogleFonts.notoSans(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Şehir: ${arazi['city']}',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'İlçe: ${arazi['district']}',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (arazi['village'] != null) // Köy/Mahalle varsa göster
              Text(
            'Köy/Mahalle: ${arazi['village']}',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: Colors.grey[600],),
              ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
