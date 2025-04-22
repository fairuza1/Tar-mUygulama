import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateLandPage extends StatefulWidget {
  final int landId;

  const UpdateLandPage({Key? key, required this.landId}) : super(key: key);

  @override
  _UpdateLandPageState createState() => _UpdateLandPageState();
}

class _UpdateLandPageState extends State<UpdateLandPage> {
  final _formKey = GlobalKey<FormState>();
  String? name, city, district, village;
  double? landSize;
  bool isLoading = false;
  int? userId;

  @override
  void initState() {
    super.initState();
    _getUserId();
    _fetchLandData();
  }

  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');
  }

  Future<void> _fetchLandData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/lands/detail/${widget.landId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        final landData = json.decode(decodedResponse);

        setState(() {
          name = landData['name'];
          city = landData['city'];
          district = landData['district'];
          village = landData['village'];
          landSize = landData['landSize'].toDouble();
          isLoading = false;
        });
      } else {
        _showSnackbar('Arazi verileri yüklenemedi. Durum Kodu: ${response.statusCode}', Colors.red);
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

  Future<void> _updateLand() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:8080/lands/${widget.landId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'city': city,
          'district': district,
          'village': village,
          'landSize': landSize,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackbar('Arazi başarıyla güncellendi.', Colors.green);
        Navigator.pop(context, true);
      } else {
        final decodedResponse = utf8.decode(response.bodyBytes);
        String errorMessage = 'Arazi güncellenemedi. Durum Kodu: ${response.statusCode}';

        try {
          final errorBody = json.decode(decodedResponse);
          if (errorBody is Map && errorBody.containsKey('error')) {
            errorMessage = errorBody['error']; // Hata mesajını 'error' anahtarından al
          }
        } catch (_) {
          // Eğer hata mesajı decode edilemezse, varsayılan hata mesajını kullan
        }

        _showSnackbar(errorMessage, Colors.red);
      }
    } catch (e) {
      _showSnackbar('Bir hata oluştu: $e', Colors.red);
    } finally {
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
        title: Text('Arazi Güncelle', style: GoogleFonts.notoSans()),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  initialValue: name ?? '',
                  decoration: const InputDecoration(labelText: 'Arazi Adı'),
                  onChanged: (value) => name = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Arazi adı boş olamaz';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  initialValue: city ?? '',
                  decoration: const InputDecoration(labelText: 'Şehir'),
                  onChanged: (value) => city = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şehir boş olamaz';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  initialValue: district ?? '',
                  decoration: const InputDecoration(labelText: 'İlçe'),
                  onChanged: (value) => district = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'İlçe boş olamaz';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  initialValue: village ?? '',
                  decoration: const InputDecoration(labelText: 'Mahalle'),
                  onChanged: (value) => village = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mahalle boş olamaz';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  initialValue: landSize?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Arazi Büyüklüğü (Hektar)'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    landSize = double.tryParse(value) ?? 0;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Arazi büyüklüğü boş olamaz';
                    }
                    if (landSize == null || landSize! <= 0) {
                      return 'Geçerli bir büyüklük girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateLand,
                  child: Text('Güncelle', style: GoogleFonts.notoSans()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                    textStyle: GoogleFonts.notoSans(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
