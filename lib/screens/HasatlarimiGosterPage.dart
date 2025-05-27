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
    userId = prefs.getInt('userId');

    if (userId != null) {
      _fetchHarvests(userId!);
    } else {
      setState(() => isLoading = false);
      _showSnackbar('Kullanıcı ID bulunamadı.', Colors.red);
    }
  }

  Future<void> _fetchHarvests(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/harvests/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      final decodedResponse = utf8.decode(response.bodyBytes);

      setState(() {
        if (response.statusCode == 200) {
          harvests = json.decode(decodedResponse);
        } else {
          harvests = [];
        }
        isLoading = false;
      });

      if (response.statusCode == 204 || harvests.isEmpty) {
        _showSnackbar('Hiç hasat bulunamadı.', Colors.orange);
      } else if (response.statusCode != 200) {
        _showSnackbar(
            'Hasatlar yüklenemedi. Durum kodu: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      setState(() => isLoading = false);
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

  Widget buildHarvestCard(Map<String, dynamic> harvest) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              harvest['plantName'] != null
                  ? 'Arazi: ${harvest['landName'] ?? 'Bilinmiyor'}'
                  : 'Hasat ID: ${harvest['id']}',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              runSpacing: 6,
              children: [
                infoRow('Hasat Tarihi', harvest['harvestDate']),
                infoRow('Kategori', harvest['categoryName'] ?? 'Bilinmiyor'),
                infoRow('Bitki', harvest['plantName']),
                infoRow('Ekim Miktarı', '${harvest['plantingAmount']}'),
                infoRow('Ekim ID', '${harvest['sowingId']}'),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DegerlendirPage(harvest: harvest),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.rate_review, size: 20),
                label: Text(
                  'Değerlendir',
                  style: GoogleFonts.notoSans(fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget infoRow(String title, String value) {
    return Row(
      children: [
        Text(
          "$title: ",
          style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.notoSans(),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hasatlarım', style: GoogleFonts.notoSans()),
        backgroundColor: Colors.green[700],
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : harvests.isEmpty
          ? Center(
        child: Text(
          'Hiç hasat bulunamadı.',
          style: GoogleFonts.notoSans(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: harvests.length,
        itemBuilder: (context, index) =>
            buildHarvestCard(harvests[index]),
      ),
    );
  }
}
