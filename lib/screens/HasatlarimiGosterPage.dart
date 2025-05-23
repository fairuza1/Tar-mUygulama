import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'DegerlendirPage.dart';

class HasatlarimiGosterPage extends StatefulWidget {
  const HasatlarimiGosterPage({Key? key}) : super(key: key);

  @override
  _HasatlarimiGosterPageState createState() => _HasatlarimiGosterPageState();
}

class _HasatlarimiGosterPageState extends State<HasatlarimiGosterPage> {
  List<dynamic> harvests = [];
  bool isLoading = true;
  int? userId;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  Future<void> _fetchUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('userId');
    });

    if (userId != null) {
      _fetchHarvests(userId!);
    } else {
      setState(() {
        isLoading = false;
      });
      _showSnackbar('Kullanıcı ID bulunamadı.', Colors.red);
    }
  }

  Future<void> _fetchHarvests(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/harvests/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        setState(() {
          harvests = json.decode(decodedResponse);
          isLoading = false;
        });
      } else if (response.statusCode == 204) {
        setState(() {
          harvests = [];
          isLoading = false;
        });
        _showSnackbar('Hiç hasat bulunamadı.', Colors.orange);
      } else {
        _showSnackbar(
            'Hasatlar yüklenemedi. Durum kodu: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Hata: $e', Colors.red);
      setState(() {
        isLoading = false;
      });
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
        title: Text('Hasatlarım', style: GoogleFonts.notoSans()),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : harvests.isEmpty
          ? Center(
        child: Text(
          'Hiç hasat bulunamadı.',
          style: GoogleFonts.notoSans(fontSize: 18, color: Colors.grey),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: harvests.length,
          itemBuilder: (context, index) {
            final harvest = harvests[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(
                        harvest['plantName'] != null
                            ? 'Arazi: ${harvest['landName'] ?? 'Bilinmiyor'}'
                            : 'Hasat ID: ${harvest['id']}',
                        style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '''
Hasat Tarihi: ${harvest['harvestDate']}
Ekim ID: ${harvest['sowingId']}
Kategori: ${harvest['categoryName'] ?? 'Bilinmiyor'}
Bitki: ${harvest['plantName']}
Ekim Miktarı: ${harvest['plantingAmount']}
                                  ''',
                        style: GoogleFonts.notoSans(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DegerlendirPage(harvest: harvest),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        child: Text('Değerlendir', style: GoogleFonts.notoSans()),
                      ),
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
