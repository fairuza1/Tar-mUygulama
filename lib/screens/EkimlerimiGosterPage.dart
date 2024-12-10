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

  @override
  void initState() {
    super.initState();
    _fetchSowings();
  }

  Future<void> _fetchSowings() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      _showSnackbar('Kullanıcı bilgileri bulunamadı.', Colors.red);
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/sowings/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        setState(() {
          sowings = json.decode(decodedResponse);
          isLoading = false;
        });
      } else {
        _showSnackbar('Ekimler yüklenemedi. Durum Kodu: ${response.statusCode}', Colors.red);
        setState(() {
          isLoading = false;
        });
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
          : ListView.builder(
        itemCount: sowings.length,
        itemBuilder: (context, index) {
          final sowing = sowings[index];
          final sowingDate = DateTime.parse(sowing['sowingDate']);
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            elevation: 4,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                '${sowing['plant']['name']} (${sowing['amount']} adet)',
                style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Arazi: ${sowing['land']['name']}'),
                  Text('Ekim Tarihi: ${sowingDate.toLocal()}'.split(' ')[0]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
