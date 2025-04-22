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
  List<int> harvestedSowings = [];
  List<dynamic> lands = [];
  bool isLoading = true;
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadHarvestedSowings();
    _fetchUserId();
    _fetchLands();
  }

  Future<void> _loadHarvestedSowings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      harvestedSowings = prefs.getStringList('harvestedSowings')?.map(int.parse).toList() ?? [];
    });
  }

  Future<void> _saveHarvestedSowings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('harvestedSowings', harvestedSowings.map((id) => id.toString()).toList());
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

  Future<void> _fetchLands() async {
    if (userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/lands?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        setState(() {
          lands = json.decode(decodedResponse);
        });
      } else {
        _showSnackbar('Araziler yüklenemedi. Durum Kodu: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Hata: $e', Colors.red);
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
          harvestedSowings.add(sowingId);
        });
        await _saveHarvestedSowings();
        _showSnackbar('Hasat başarıyla tamamlandı!', Colors.green);
      } else {
        _showSnackbar('Hasat işlemi başarısız. Durum Kodu: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Hata: $e', Colors.red);
    }
  }

  Future<void> _deleteSowing(int sowingId) async {
    bool? confirmed = await _showDeleteConfirmationDialog();
    if (confirmed == true) {
      try {
        final response = await http.delete(
          Uri.parse('http://10.0.2.2:8080/api/sowings/$sowingId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          setState(() {
            sowings.removeWhere((s) => s['id'] == sowingId);
          });
          _showSnackbar('Ekim başarıyla silindi.', Colors.green);
        } else {
          _showSnackbar('Silme başarısız. Durum Kodu: ${response.statusCode}', Colors.red);
        }
      } catch (e) {
        _showSnackbar('Hata: $e', Colors.red);
      }
    }
  }

  Future<bool?> _showDeleteConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Hayır"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Evet"),
          ),
        ],
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
            final isHarvested = harvestedSowings.contains(sowing['id']);
            final land = lands.firstWhere(
                  (land) => land['id'] == sowing['landId'],
              orElse: () => {},
            );
            final remainingSize = land.isNotEmpty ? land['remainingSize'] : 0.0;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(
                  '${sowing['plantName']} (${sowing['categoryName']})',
                  style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Ekim Tarihi: ${sowing['sowingDate']} \nArazi: ${sowing['landName']} \nMiktar: ${sowing['plantingAmount']} \nKalan Alan: $remainingSize m²',
                  style: GoogleFonts.notoSans(),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hasat Et butonu
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isHarvested
                            ? null
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
                    const SizedBox(height: 8),
                    // Sil butonu
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _deleteSowing(sowing['id']),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: Text(
                          'Sil',
                          style: GoogleFonts.notoSans(color: Colors.white),
                        ),
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
