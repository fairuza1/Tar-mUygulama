import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class EkimlerimiGosterPage extends StatefulWidget {
  const EkimlerimiGosterPage({Key? key}) : super(key: key);

  @override
  _EkimlerimiGosterPageState createState() => _EkimlerimiGosterPageState();
}

class _EkimlerimiGosterPageState extends State<EkimlerimiGosterPage> {
  List<dynamic> sowings = [];
  bool isLoading = true;
  int? userId;

  @override
  void initState() {
    super.initState();
    _fetchUserId(); // Kullanıcı ID'sini al
  }

  // Kullanıcı ID'sini SharedPreferences'den al
  Future<void> _fetchUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('userId');
    });
    print("User ID: $userId");

    // Kullanıcı ID'si alındıysa ekim verilerini çek
    if (userId != null) {
      _fetchSowings();
    }
  }

  // Ekimleri almak için API çağrısı
  Future<void> _fetchSowings() async {
    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      print("User ID is null, cannot fetch sowings.");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/sowings/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      // Durum kodu ve yanıtı konsola yazdır
      print('API Response Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        setState(() {
          sowings = json.decode(decodedResponse);
          isLoading = false;
        });

        // Ekim verilerini konsola yazdır
        if (sowings.isNotEmpty) {
          print('Ekimlerim:');
          for (var sowing in sowings) {
            print('Plant: ${sowing['plantName']}, Category: ${sowing['categoryName']}, Land: ${sowing['landName']}');
          }
        } else {
          print('Ekim listesi boş.');
        }
      } else if (response.statusCode == 204) {
        setState(() {
          sowings = [];
          isLoading = false;
        });
        print('Hiç ekim yapılmamış.');
      } else {
        _showSnackbar('Ekimler yüklenemedi. Durum Kodu: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Hata: $e', Colors.red);
      print("Error: $e"); // Hata mesajını yazdır
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
        title: Text('Ekimlerim', style: GoogleFonts.notoSans()),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sowings.isEmpty
          ? Center(
        child: Text(
          'Hiç ekim yapılmamış.',
          style: GoogleFonts.notoSans(fontSize: 18, color: Colors.grey),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: sowings.length,
          itemBuilder: (context, index) {
            final sowing = sowings[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(
                  '${sowing['plantName']} (${sowing['categoryName']})',
                  style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Ekim Tarihi: ${sowing['sowingDate']} \nArazi: ${sowing['landName']} \nMiktar: ${sowing['plantingAmount']}',
                  style: GoogleFonts.notoSans(),
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    // Hasat işlemi başlatılıyor
                    _showSnackbar('Hasat işlemi başlatıldı: ${sowing['landName']}', Colors.green);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text(
                    'Hasat Et',
                    style: GoogleFonts.notoSans(color: Colors.white),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
