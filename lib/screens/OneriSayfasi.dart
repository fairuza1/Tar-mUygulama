import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/svg.dart';

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
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadIller();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadIller() async {
    try {
      final data = await _loadJsonData('assets/Data/sehirler.json');
      setState(() {
        iller = data.map<String>((e) => e['sehir_adi'] as String).toList();
      });
    } catch (e) {
      setState(() {
        _error = "Şehir verileri yüklenemedi";
      });
    }
  }

  Future<void> _loadIlceler() async {
    if (selectedIl == null) return;
    try {
      setState(() => _loading = true);
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
    } catch (e) {
      setState(() {
        _error = "İlçe verileri yüklenemedi";
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadKoyler() async {
    if (selectedIlce == null || selectedIl == null) return;

    final koyFiles = [
      'assets/Data/mahalleler-1.json',
      'assets/Data/mahalleler-2.json',
      'assets/Data/mahalleler-3.json',
      'assets/Data/mahalleler-4.json',
    ];

    try {
      setState(() => _loading = true);
      List<String> tumKoyler = [];

      for (var file in koyFiles) {
        try {
          final data = await _loadJsonData(file);
          tumKoyler.addAll(data
              .where((e) => e['sehir_adi'] == selectedIl && e['ilce_adi'] == selectedIlce)
              .map<String>((e) => e['mahalle_adi'] as String)
              .toList());
        } catch (e) {
          debugPrint("$file yüklenirken hata: $e");
        }
      }

      setState(() {
        koyler = tumKoyler;
        selectedKoy = null;
      });
    } catch (e) {
      setState(() {
        _error = "Köy verileri yüklenemedi";
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<List<dynamic>> _loadJsonData(String path) async {
    final jsonString = await rootBundle.loadString(path);
    return json.decode(jsonString) as List<dynamic>;
  }

  Future<void> fetchOneriler() async {
    if (selectedIl == null || selectedIlce == null || selectedKoy == null) {
      setState(() {
        _error = "Lütfen tüm konum alanlarını seçin";
        _oneriler = [];
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
          _error = "Veri alınamadı (${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Bağlantı hatası: $e";
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
    required IconData icon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            prefixIcon: Icon(icon, color: Colors.green[700]),
            labelStyle: TextStyle(color: Colors.grey[600]),
          ),
          value: selectedValue,
          items: items.map((e) => DropdownMenuItem(
            value: e,
            child: Text(e, style: TextStyle(fontSize: 14)),
          )).toList(),
          onChanged: onChanged,
          style: TextStyle(color: Colors.grey[800], fontSize: 14),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(Icons.arrow_drop_down, color: Colors.green[700]),
          isExpanded: true,
        ),
      ),
    );
  }

  String _plantNameToImagePath(String plantName) {
    String cleaned = plantName
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
    return 'assets/images/plants/$cleaned.png';
  }

  Widget _buildOneriCard(OneriModel oneri) {
    final imagePath = _plantNameToImagePath(oneri.plantName);
    final ratingPercentage = (oneri.totalScore / 5.0) * 100;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Bitki detay sayfasına yönlendirme
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.green[50],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(Icons.eco, size: 40, color: Colors.green[300]),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      oneri.plantName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 120,
                          child: LinearProgressIndicator(
                            value: oneri.totalScore / 5.0,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getRatingColor(oneri.totalScore),
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${oneri.totalScore.toStringAsFixed(1)}/5',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${ratingPercentage.toStringAsFixed(0)}% başarı oranı',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return Colors.green[400]!;
    if (rating >= 3) return Colors.lightGreen[400]!;
    if (rating >= 2) return Colors.amber[600]!;
    return Colors.orange[600]!;
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/images/empty_state.svg',
          width: 200,
          color: Colors.green[100],
        ),
        SizedBox(height: 24),
        Text(
          'Henüz öneri bulunamadı',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Konum seçerek bu bölge için önerileri görüntüleyin',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Bitki Önerileri", style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        )),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.green[700],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              // Bilgi sayfasına yönlendirme
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Konum Seçim Bölümü
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
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
                    icon: Icons.location_city,
                  ),
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
                    icon: Icons.map,
                  ),
                  _buildDropdown(
                    label: 'Mahalle/Köy',
                    items: koyler,
                    selectedValue: selectedKoy,
                    onChanged: (val) {
                      setState(() {
                        selectedKoy = val;
                      });
                    },
                    icon: Icons.place,
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : fetchOneriler,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "ÖNERİLERİ GÖSTER",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Sonuçlar Bölümü
            Expanded(
              child: _error != null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red[300],
                    ),
                    SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: fetchOneriler,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("Tekrar Dene"),
                    ),
                  ],
                ),
              )
                  : _oneriler.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                controller: _scrollController,
                itemCount: _oneriler.length,
                itemBuilder: (context, index) {
                  return _buildOneriCard(_oneriler[index]);
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
