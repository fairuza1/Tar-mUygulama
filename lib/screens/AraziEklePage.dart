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
  final _formKey = GlobalKey<FormState>();
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

  Future<void> _loadSehirler() async {
    final response = await _loadJsonData('assets/Data/sehirler.json');
    setState(() {
      iller = response.map((item) => item['sehir_adi'] as String).toList();
    });
  }

  Future<void> _loadIlceler() async {
    if (selectedIl == null) return;

    final response = await _loadJsonData('assets/Data/ilceler.json');
    setState(() {
      ilceler = response
          .where((item) => item['sehir_adi'] == selectedIl)
          .map((item) => item['ilce_adi'] as String)
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

    List<String> allKoyler = [];
    for (var file in koyFiles) {
      final response = await _loadJsonData(file);
      allKoyler.addAll(
        response
            .where((item) =>
        item['sehir_adi'] == selectedIl &&
            item['ilce_adi'] == selectedIlce)
            .map((item) => item['mahalle_adi'] as String)
            .toList(),
      );
    }

    setState(() {
      koyler = allKoyler;
      selectedKoy = null;
    });
  }

  Future<List<dynamic>> _loadJsonData(String path) async {
    final String response = await rootBundle.loadString(path);
    return json.decode(response) as List<dynamic>;
  }

  Future<void> _addLand() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    final newLand = {
      'name': _landNameController.text,
      'landSize': int.tryParse(_landSizeController.text),
      'city': selectedIl,
      'district': selectedIlce,
      'village': selectedKoy,
      'userId': userId,
    };

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/lands'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(newLand),
      );

      if (response.statusCode == 201) {
        _showSnackbar('Arazi başarıyla kaydedildi!', Colors.green);
        Navigator.pushNamed(context, '/ArazilerimiGosterPage');
      } else {
        _showSnackbar(
            'Arazi kaydedilmedi. Durum Kodu: ${response.statusCode}', Colors.red);
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

  Widget _buildDropdownField({
    required String hint,
    required List<String> items,
    String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: inputType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Bu alan boş bırakılamaz.';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arazi Ekle'),
        backgroundColor: const Color(0xFF228B22),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/arazi-ekle.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.terrain, size: 80, color: Colors.white),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: _landNameController,
                      label: 'Arazi Adı',
                      icon: Icons.landscape,
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: _landSizeController,
                      label: 'Arazi Büyüklüğü (hektar)',
                      icon: Icons.area_chart,
                      inputType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    _buildDropdownField(
                      hint: 'İl Seçin',
                      items: iller,
                      value: selectedIl,
                      onChanged: (value) {
                        setState(() => selectedIl = value);
                        _loadIlceler();
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildDropdownField(
                      hint: 'İlçe Seçin',
                      items: ilceler,
                      value: selectedIlce,
                      onChanged: (value) {
                        setState(() => selectedIlce = value);
                        _loadKoyler();
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildDropdownField(
                      hint: 'Köy/Mahalle Seçin',
                      items: koyler,
                      value: selectedKoy,
                      onChanged: (value) {
                        setState(() => selectedKoy = value);
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _addLand,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: const Color(0xFF228B22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Arazi Ekle',
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
