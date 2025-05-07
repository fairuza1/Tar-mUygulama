import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class DegerlendirPage extends StatefulWidget {
  final Map<String, dynamic> harvest;

  const DegerlendirPage({Key? key, required this.harvest}) : super(key: key);

  @override
  _DegerlendirPageState createState() => _DegerlendirPageState();
}

class _DegerlendirPageState extends State<DegerlendirPage> {
  final _commentController = TextEditingController();
  int _rating = 0;
  String _harvestStatus = 'normal';

  Future<void> _submitRating(BuildContext context) async {
    final url = Uri.parse('http://10.0.2.2:8080/api/ratings');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'harvestId': widget.harvest['id'],
          'rating': _rating,
          'comment': _commentController.text,
          'harvestStatus': _harvestStatus,
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hasat Bilgileri', style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Text('🌿 Bitki: ${widget.harvest['plantName']}', style: GoogleFonts.notoSans()),
            Text('📦 Kategori: ${widget.harvest['categoryName']}', style: GoogleFonts.notoSans()),
            Text('⚖️ Ekim Miktarı: ${widget.harvest['plantingAmount']}', style: GoogleFonts.notoSans()),
            Text('🆔 Hasat ID: ${widget.harvest['id']}', style: GoogleFonts.notoSans(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return TextField(
      controller: _commentController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: '💬 Yorum (Opsiyonel)',
        labelStyle: GoogleFonts.notoSans(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }

  Widget _buildRatingSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('⭐ Puan', style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold)),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.green,
            inactiveTrackColor: Colors.green.shade100,
            thumbColor: Colors.green,
            overlayColor: Colors.green.withAlpha(32),
            valueIndicatorColor: Colors.green,
          ),
          child: Slider(
            value: _rating.toDouble(),
            min: 1,
            max: 5,
            divisions: 5,
            label: '$_rating',
            onChanged: (value) {
              setState(() {
                _rating = value.toInt();
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (i) => Icon(Icons.star, color: i < _rating ? Colors.amber : Colors.grey)),
        ),
      ],
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
      items: ['çok kötü', 'kötü', 'normal', 'iyi', 'çok iyi'].map((value) {
        return DropdownMenuItem(
          value: value,
          child: Text(value, style: GoogleFonts.notoSans()),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _harvestStatus = value!;
        });
      },
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
          children: [
            _buildHarvestInfoCard(),
            const SizedBox(height: 20),
            _buildCommentSection(),
            const SizedBox(height: 20),
            _buildRatingSlider(),
            const SizedBox(height: 20),
            _buildStatusDropdown(),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
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
            ),
          ],
        ),
      ),
    );
  }
}
