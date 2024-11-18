import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AraziEklePage extends StatefulWidget {
  const AraziEklePage({Key? key}) : super(key: key);

  @override
  _AraziEklePageState createState() => _AraziEklePageState();
}

class _AraziEklePageState extends State<AraziEklePage> {
  final TextEditingController _landNameController = TextEditingController();
  final TextEditingController _landSizeController = TextEditingController();
  String? selectedIl;
  String? selectedIlce;
  String? selectedKoy;
  List<String> iller = [];
  List<String> ilceler = [];
  List<String> koyler = [];

  @override
  void initState() {
    super.initState();
    _loadSehirler();
  }

  // Şehir verilerini yükleme
  Future<void> _loadSehirler() async {
    final String response = await rootBundle.loadString('assets/Data/sehirler.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      iller = data.map((item) => item['sehir_adi'] as String).toList();
    });
  }

  // İlçe verilerini yükleme
  Future<void> _loadIlceler() async {
    if (selectedIl == null) return;

    final String response = await rootBundle.loadString('assets/Data/ilceler.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      ilceler = data
          .where((item) => item['sehir_adi'] == selectedIl)  // Şehir adına göre filtreleme
          .map((item) => item['ilce_adi'] as String)
          .toList();
      selectedIlce = null;  // Seçili ilçeyi sıfırla
      koyler = [];
      selectedKoy = null;
    });
  }

  // Köy/Mahalle verilerini yükleme
  Future<void> _loadKoyler() async {
    if (selectedIlce == null) return;

    final koyFiles = [
      'assets/Data/mahalleler-1.json',
      'assets/Data/mahalleler-2.json',
      'assets/Data/mahalleler-3.json',
      'assets/Data/mahalleler-4.json',
    ];

    List<String> allKoyler = [];
    for (var file in koyFiles) {
      final String response = await rootBundle.loadString(file);
      final List<dynamic> data = json.decode(response);
      final filteredKoyler = data
          .where((item) => item['sehir_adi'] == selectedIl && item['ilce_adi'] == selectedIlce)  // İl ve ilçe filtresi
          .map((item) => item['mahalle_adi'] as String?)
          .where((koy) => koy != null)
          .cast<String>()
          .toList();
      allKoyler.addAll(filteredKoyler);
    }

    setState(() {
      koyler = allKoyler;
      selectedKoy = null;
    });
  }

  // Arazi ekleme işlemi
  Future<void> _addLand() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (_landNameController.text.isEmpty ||
        _landSizeController.text.isEmpty ||
        selectedIl == null ||
        selectedIlce == null) {
      _showSnackbar('Lütfen tüm alanları doldurun.', Colors.red);
      return;
    }

    final newLand = {
      'name': _landNameController.text,
      'landSize': int.tryParse(_landSizeController.text),
      'city': selectedIl,
      'district': selectedIlce,
      'village': selectedKoy,
      'user': {'id': userId}
    };

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/lands'), // localhost yerine 10.0.2.2 kullanmalısınız
        headers: {'Content-Type': 'application/json'},
        body: json.encode(newLand),
      );

      if (response.statusCode == 200) {
        _showSnackbar('Arazi başarıyla kaydedildi!', Colors.green);
        Navigator.pushNamed(context, '/land-list');
      } else {
        _showSnackbar('Arazi kaydedilemedi.', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Hata: $e', Colors.red);
    }
  }

  // Snackbar mesajı gösterme
  void _showSnackbar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arazi Ekle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _landNameController,
              decoration: InputDecoration(labelText: 'Arazi Adı'),
            ),
            TextField(
              controller: _landSizeController,
              decoration: InputDecoration(labelText: 'Arazi Büyüklüğü (hektar)'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              value: selectedIl,
              hint: Text('İl Seçin'),
              items: iller.map((il) => DropdownMenuItem(value: il, child: Text(il))).toList(),
              onChanged: (value) {
                setState(() {
                  selectedIl = value;
                });
                _loadIlceler();  // İl seçildiğinde ilçeleri yükle
              },
            ),
            DropdownButtonFormField<String>(
              value: selectedIlce,
              hint: Text('İlçe Seçin'),
              items: ilceler.map((ilce) => DropdownMenuItem(value: ilce, child: Text(ilce))).toList(),
              onChanged: (value) {
                setState(() {
                  selectedIlce = value;
                });
                _loadKoyler();  // İlçe seçildiğinde mahalleleri yükle
              },
            ),
            DropdownButtonFormField<String>(
              value: selectedKoy,
              hint: Text('Köy/Mahalle Seçin'),
              items: koyler.map((koy) => DropdownMenuItem(value: koy, child: Text(koy))).toList(),
              onChanged: (value) {
                setState(() {
                  selectedKoy = value;
                });
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addLand,
              child: Text('Arazi Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}
//final response = await http.get(Uri.parse('http://localhost:8080/lands'));
