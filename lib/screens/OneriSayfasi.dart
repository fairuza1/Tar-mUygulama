import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OneriSayfasi extends StatefulWidget {
  @override
  _OneriSayfasiState createState() => _OneriSayfasiState();
}

class _OneriSayfasiState extends State<OneriSayfasi> {
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();

  List<OneriModel> _oneriler = [];
  bool _loading = false;
  String? _error;

  Future<void> fetchOneriler() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final city = _cityController.text.trim();
    final district = _districtController.text.trim();
    final village = _villageController.text.trim();

    if (city.isEmpty || district.isEmpty || village.isEmpty) {
      setState(() {
        _loading = false;
        _error = "Lütfen tüm konum alanlarını doldurun.";
      });
      return;
    }

    final uri = Uri.parse(
        'http://10.0.2.2:8080/api/ratings/recommendations?city=$city&district=$district&village=$village');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          _oneriler = jsonData.map((e) => OneriModel.fromJson(e)).toList();
        });
      } else {
        setState(() {
          _error = "Sunucudan veri alınamadı (${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Bir hata oluştu: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bitki Önerileri"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _cityController,
              decoration: InputDecoration(labelText: 'İl'),
            ),
            TextField(
              controller: _districtController,
              decoration: InputDecoration(labelText: 'İlçe'),
            ),
            TextField(
              controller: _villageController,
              decoration: InputDecoration(labelText: 'Mahalle/Köy'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchOneriler,
              child: Text("Önerileri Göster"),
            ),
            const SizedBox(height: 16),
            _loading
                ? CircularProgressIndicator()
                : _error != null
                ? Text(
              _error!,
              style: TextStyle(color: Colors.red, fontSize: 16),
            )
                : _oneriler.isEmpty
                ? Text("Henüz veri yok.")
                : Expanded(
              child: ListView.builder(
                itemCount: _oneriler.length,
                itemBuilder: (context, index) {
                  final oneri = _oneriler[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin:
                    const EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    child: ListTile(
                      title: Text(
                        oneri.plantName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Ortalama Puan: ${oneri.totalScore.toStringAsFixed(2)}",
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OneriModel {
  final String plantName;
  final double totalScore;

  OneriModel({required this.plantName, required this.totalScore});

  factory OneriModel.fromJson(Map<String, dynamic> json) {
    return OneriModel(
      plantName: json['plantName'],
      totalScore: (json['totalScore'] as num).toDouble(),
    );
  }
}
