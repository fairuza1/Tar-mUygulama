// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class DegerlendirPage extends StatefulWidget {
  final Map<String, dynamic> harvest;

  const DegerlendirPage({Key? key, required this.harvest}) : super(key: key);

  @override
  State<DegerlendirPage> createState() => _DegerlendirPageState();
}

class _DegerlendirPageState extends State<DegerlendirPage> {
  final _commentController = TextEditingController();

  Map<String, int> categoryRatings = {
    'Lezzet': 3,
    'Verimlilik': 3,
    'Dayanıklılık': 3,
    'Görünüm': 3,
    'Zorluk': 3,
  };

  final Map<String, String> categoryDescriptions = {
    'Lezzet': 'Tüketici ya da üretici açısından ürünün tadı',
    'Verimlilik': 'Beklenen ürün miktarına göre başarı durumu',
    'Dayanıklılık': 'Hasat sonrası raf ömrü, bozulma durumu',
    'Görünüm': 'Fiziksel bütünlük, renk, deformasyon durumu',
    'Zorluk': 'Üretim sürecindeki zorluklar, uğraştırıcılık seviyesi',
  };

  final Map<String, int> _statusMap = {
    'çok kötü': 1,
    'kötü': 2,
    'normal': 3,
    'iyi': 4,
    'çok iyi': 5,
  };
  String _harvestStatus = 'normal';
  int _harvestStatusValue = 3;

  List<String> selectedTags = [];
  final List<String> allTags = [
    '🌾 Toprak verimliydi',
    '💧 Sulama sorunluydu',
    '🐛 Zararlı istilası vardı',
    '☀️ Hava koşulları iyiydi',
    '🌬️ Rüzgar etkiliydi',
    '🌧️ Aşırı yağmur vardı',
  ];

  Future<void> _submitRating(BuildContext context) async {
    final url = Uri.parse('http://10.0.2.2:8080/api/ratings');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'harvestId': widget.harvest['id'],
          'comment': _commentController.text,
          'harvestStatus': _harvestStatusValue,
          'categoryRatings': categoryRatings,
          'tags': selectedTags,
        }),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Değerlendirme kaydedildi!')),
        );
        Navigator.pushReplacementNamed(context, '/degerlendirmeler');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Hata: $e')),
      );
    }
  }

  Widget _buildHarvestInfoCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hasat Bilgileri', style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Text('🌿 Bitki: ${widget.harvest['plantName']}', style: GoogleFonts.notoSans()),
            Text('📦 Kategori: ${widget.harvest['categoryName']}', style: GoogleFonts.notoSans()),
            Text('⚖️ Ekim Miktarı: ${widget.harvest['plantingAmount']}', style: GoogleFonts.notoSans()),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentField() {
    return TextField(
      controller: _commentController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: '💬 Yorum (opsiyonel)',
        labelStyle: GoogleFonts.notoSans(),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showCategoryInfo(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category, style: GoogleFonts.notoSans(fontWeight: FontWeight.bold)),
        content: Text(categoryDescriptions[category] ?? '', style: GoogleFonts.notoSans()),
        actions: [
          TextButton(
            child: const Text("Kapat"),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  Widget _buildCategorySliders() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📊 Kategori Bazlı Puanlama', style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...categoryRatings.keys.map((category) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(category, style: GoogleFonts.notoSans(fontSize: 15)),
                    const SizedBox(width: 5),
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 20, color: Colors.blueGrey),
                      onPressed: () => _showCategoryInfo(category),
                    )
                  ],
                ),
                Slider(
                  value: categoryRatings[category]!.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: categoryRatings[category].toString(),
                  onChanged: (val) {
                    setState(() => categoryRatings[category] = val.toInt());
                  },
                ),
              ],
            ))
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: '🌾 Hasat Durumu',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      value: _harvestStatus,
      items: _statusMap.keys.map((label) {
        return DropdownMenuItem<String>(
          value: label,
          child: Text(label, style: GoogleFonts.notoSans()),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _harvestStatus = value!;
          _harvestStatusValue = _statusMap[value]!;
        });
      },
    );
  }

  Widget _buildTagSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🏷️ Etiketler (Durum Notları)', style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: allTags.map((tag) {
            final selected = selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag, style: GoogleFonts.notoSans()),
              selected: selected,
              selectedColor: Colors.green.shade100,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    selectedTags.add(tag);
                  } else {
                    selectedTags.remove(tag);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hasat Değerlendirme', style: GoogleFonts.notoSans()),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHarvestInfoCard(),
            const SizedBox(height: 20),
            _buildCategorySliders(),
            const SizedBox(height: 20),
            _buildTagSelector(),
            const SizedBox(height: 20),
            _buildStatusDropdown(),
            const SizedBox(height: 20),
            _buildCommentField(),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _submitRating(context),
              icon: const Icon(Icons.send),
              label: Text('Değerlendirmeyi Gönder', style: GoogleFonts.notoSans()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
