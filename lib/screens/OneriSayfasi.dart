import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class OneriSayfasi extends StatefulWidget {
  @override
  _OneriSayfasiState createState() => _OneriSayfasiState();
}

class _OneriSayfasiState extends State<OneriSayfasi> {
  String? selectedIl;
  String? selectedIlce;
  String? selectedKoy;

  List<String> iller = [];
  List<String> ilceler = [];
  List<String> koyler = [];

  List<OneriModel> _oneriler = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIller();
  }

  Future<void> _loadIller() async {
    final data = await _loadJsonData('assets/Data/sehirler.json');
    setState(() {
      iller = data.map<String>((e) => e['sehir_adi'] as String).toList();
    });
  }

  Future<void> _loadIlceler() async {
    if (selectedIl == null) return;
    final data = await _loadJsonData('assets/Data/ilceler.json');
    setState(() {
      ilceler = data
          .where((e) => e['sehir_adi'] == selectedIl)
          .map<String>((e) => e['ilce_adi'] as String)
          .toList();
      selectedIlce = null;
      koyler = [];
      selectedKoy = null;
    });
  }

  Future<void> _loadKoyler() async {
    if (selectedIlce == null) return;

    final koyFiles = [
      'assets/Data/mahalleler-1.json',
      'assets/Data/mahalleler-2.json',
      'assets/Data/mahalleler-3.json',
      'assets/Data/mahalleler-4.json',
    ];

    List<String> tumKoyler = [];
    for (var file in koyFiles) {
      final data = await _loadJsonData(file);
      tumKoyler.addAll(data
          .where((e) => e['sehir_adi'] == selectedIl && e['ilce_adi'] == selectedIlce)
          .map<String>((e) => e['mahalle_adi'] as String)
          .toList());
    }

    setState(() {
      koyler = tumKoyler;
      selectedKoy = null;
    });
  }

  Future<List<dynamic>> _loadJsonData(String path) async {
    final jsonString = await rootBundle.loadString(path);
    return json.decode(jsonString) as List<dynamic>;
  }

  Future<void> fetchOneriler() async {
    if (selectedIl == null || selectedIlce == null || selectedKoy == null) {
      setState(() {
        _error = "Lütfen tüm konum alanlarını seçin.";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _oneriler = [];
    });

    final uri = Uri.parse(
        'http://10.0.2.2:8080/api/ratings/recommendations?city=$selectedIl&district=$selectedIlce&village=$selectedKoy');

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

  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required String? selectedValue,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      value: selectedValue,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bitki Önerileri"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDropdown(
              label: 'İl',
              items: iller,
              selectedValue: selectedIl,
              onChanged: (val) {
                setState(() {
                  selectedIl = val;
                  selectedIlce = null;
                  selectedKoy = null;
                  ilceler = [];
                  koyler = [];
                });
                _loadIlceler();
              },
            ),
            const SizedBox(height: 10),
            _buildDropdown(
              label: 'İlçe',
              items: ilceler,
              selectedValue: selectedIlce,
              onChanged: (val) {
                setState(() {
                  selectedIlce = val;
                  selectedKoy = null;
                  koyler = [];
                });
                _loadKoyler();
              },
            ),
            const SizedBox(height: 10),
            _buildDropdown(
              label: 'Mahalle/Köy',
              items: koyler,
              selectedValue: selectedKoy,
              onChanged: (val) {
                setState(() {
                  selectedKoy = val;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchOneriler,
              child: _loading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Önerileri Göster"),
            ),
            const SizedBox(height: 20),
            _error != null
                ? Text(_error!, style: TextStyle(color: Colors.red))
                : _oneriler.isEmpty
                ? Text("Henüz veri yok.")
                : Expanded(
              child: ListView.builder(
                itemCount: _oneriler.length,
                itemBuilder: (context, index) {
                  final oneri = _oneriler[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    child: ListTile(
                      title: Text(oneri.plantName,
                          style:
                          TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          "Ortalama Puan: ${oneri.totalScore.toStringAsFixed(2)}"),
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
