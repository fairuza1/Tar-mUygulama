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
  List<int> harvestedSowings = []; // Hasat edilen sowing ID'leri
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
      _fetchSowings();
    }
  }

  Future<void> _fetchSowings() async {
    if (userId == null) return;

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
      } else if (response.statusCode == 204) {
        setState(() {
          sowings = [];
          isLoading = false;
        });
      } else {
        _showSnackbar('Ekimler yüklenemedi. Durum Kodu: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Hata: $e', Colors.red);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _harvestSowing(int sowingId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/harvests'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'sowingId': sowingId, 'harvestDate': DateTime.now().toIso8601String()}),
      );

      if (response.statusCode == 201) {
        setState(() {
          harvestedSowings.add(sowingId); // Hasat edilen ID'yi listeye ekle
        });
        _showSnackbar('Hasat başarıyla tamamlandı!', Colors.green);
      } else {
        _showSnackbar('Hasat işlemi başarısız. Durum Kodu: ${response.statusCode}', Colors.red);
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
            final isHarvested = harvestedSowings.contains(sowing['id']); // Hasat edilmiş mi?

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
                  onPressed: isHarvested
                      ? null // Eğer hasat edilmişse butonu devre dışı bırak
                      : () => _harvestSowing(sowing['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isHarvested ? Colors.grey : Colors.green,
                  ),
                  child: Text(
                    isHarvested ? 'Hasat Edildi' : 'Hasat Et',
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
