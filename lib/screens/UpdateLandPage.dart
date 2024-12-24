import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UpdateLandPage extends StatefulWidget {
  const UpdateLandPage({Key? key, required this.landId}) : super(key: key);

  final int landId; // Arazi ID'sini almak için bu parametreyi ekledim.

  @override
  _UpdateLandPageState createState() => _UpdateLandPageState();
}

class _UpdateLandPageState extends State<UpdateLandPage> {
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
    _loadInitialData(); // Gerekli başlangıç verisini yükle
  }

  // Şehir verilerini yükler
  Future<void> _loadSehirler() async {
    final response = await _loadJsonData('assets/Data/sehirler.json');
    setState(() {
      iller = response.map((item) => item['sehir_adi'] as String).toList();
    });
  }

  // İlçeleri yükler
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

    // İlçe seçildikten sonra köyleri yükleyin
    if (selectedIlce != null) {
      _loadKoyler();
    }
  }

  // Köyleri yükler
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
        item['sehir_adi'] == selectedIl && item['ilce_adi'] == selectedIlce)
            .map((item) => item['mahalle_adi'] as String)
            .toList(),
      );
    }

    setState(() {
      koyler = allKoyler;
      selectedKoy = null; // Köyler yüklendikten sonra, seçilen köy sıfırlanır.
    });
  }

  // JSON verilerini yükler
  Future<List<dynamic>> _loadJsonData(String path) async {
    final String response = await rootBundle.loadString(path);
    return json.decode(response) as List<dynamic>;
  }

  // Başlangıç verisini yükler
  Future<void> _loadInitialData() async {
    // API'den gelen veri ile güncelleme işlemi
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/lands/${widget.landId}'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _landNameController.text = data['name'];
        _landSizeController.text = data['landSize'].toString();
        selectedIl = data['city'];
        selectedIlce = data['district'];
        selectedKoy = data['village'];

        // İl, ilçe ve köy verilerini yükle
        _loadIlceler();
      });
    } else {
      // Yanıtın içeriğini yazdıralım
      print('API Hata: ${response.statusCode}');
      print('Hata Detayı: ${response.body}');
      _showSnackbar('Arazi verileri yüklenemedi. Durum Kodu: ${response.statusCode}', Colors.red);
    }
  }


  // Araziyi günceller
  Future<void> _updateLand() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    final updatedLand = {
      'name': _landNameController.text,
      'landSize': int.tryParse(_landSizeController.text),
      'city': selectedIl,
      'district': selectedIlce,
      'village': selectedKoy,
      'userId': userId,
    };

    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:8080/lands/${widget.landId}'), // Arazi ID'si dinamik olarak kullanılıyor
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedLand),
      );

      if (response.statusCode == 200) {
        _showSnackbar('Arazi başarıyla güncellendi!', Colors.green);
        Navigator.pushNamed(context, '/ArazilerimiGosterPage');
      } else {
        _showSnackbar('Arazi güncellenmedi. Durum Kodu: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Hata: $e', Colors.red);
    }
  }

  // Snackbar gösterir
  void _showSnackbar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Dropdown form alanı oluşturur
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

  // Text form alanı oluşturur
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
        title: const Text('Arazi Güncelle'),
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
                      onPressed: _updateLand,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF228B22),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Güncelle'),
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
