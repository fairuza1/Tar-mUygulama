import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DegerlendirmelerimiListelePage extends StatefulWidget {
  const DegerlendirmelerimiListelePage({Key? key}) : super(key: key);

  @override
  State<DegerlendirmelerimiListelePage> createState() =>
      _DegerlendirmelerimiListelePageState();
}

class _DegerlendirmelerimiListelePageState
    extends State<DegerlendirmelerimiListelePage> {
  List<dynamic> ratings = [];
  bool isLoading = true;
  String errorMessage = '';

  final Map<int, String> _statusTextMap = {
    5: 'Çok İyi',
    4: 'İyi',
    3: 'Normal',
    2: 'Kötü',
    1: 'Çok Kötü',
  };

  @override
  void initState() {
    super.initState();
    fetchRatings();
  }

  Future<void> fetchRatings() async {
    final url = Uri.parse('http://10.0.2.2:8080/api/ratings');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          // UTF-8 karakter çözümlemesi
          ratings = jsonDecode(utf8.decode(response.bodyBytes));
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = '❌ Değerlendirmeler alınamadı';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = '❌ Hata oluştu: $e';
        isLoading = false;
      });
    }
  }

  Widget buildRatingCard(dynamic rating) {
    final dynamic rawStatus = rating['harvestStatus'];
    final int? statusValue = rawStatus is int
        ? rawStatus
        : int.tryParse(rawStatus.toString());

    final String statusText =
        _statusTextMap[statusValue] ?? 'Durum belirtilmemiş';

    final dynamic amount = rating['amount'] ?? 'Belirtilmemiş';

    final dynamic yieldValue = rating['yieldPerSquareMeter'];
    final String yieldText = (yieldValue != null)
        ? "${(yieldValue as num).toStringAsFixed(2)} kg/m²"
        : "Hesaplanamadı";

    Color yieldColor;
    if (yieldValue == null) {
      yieldColor = Colors.grey;
    } else if (yieldValue >= 1.5) {
      yieldColor = Colors.green;
    } else if (yieldValue >= 1.0) {
      yieldColor = Colors.orange;
    } else {
      yieldColor = Colors.redAccent;
    }

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                const Icon(Icons.agriculture, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  "Hasat ID: ${rating['harvestId']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Genel bilgiler
            Text("🆔 Değerlendirme ID: ${rating['id']}",
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Text("🌱 Bitki Adı: ${rating['plantName'] ?? 'Bilinmiyor'}",
                style: const TextStyle(fontSize: 15)),
            Text("📅 Ekim Tarihi: ${rating['plantingDate'] ?? 'Belirtilmemiş'}",
                style: const TextStyle(fontSize: 15)),
            Text("🧪 Ekim Yöntemi: ${rating['plantingMethod'] ?? 'Belirtilmemiş'}",
                style: const TextStyle(fontSize: 15)),
            const Divider(height: 16, thickness: 1),
            Text("📍 Arazi: ${rating['landName'] ?? 'Belirtilmemiş'} (${rating['landSize']} m²)",
                style: const TextStyle(fontSize: 15)),
            Text("📌 Konum: ${rating['landLocation'] ?? 'Bilinmiyor'}",
                style: const TextStyle(fontSize: 15)),

            const Divider(height: 16, thickness: 1),

            // Değerlendirme bilgileri
            Text("⭐ Puan: ${rating['totalScore'] ?? 'Belirtilmemiş'}",
                style: const TextStyle(fontSize: 15)),
            Text(
              "💬 Yorum: ${rating['comment']?.trim().isNotEmpty == true ? rating['comment'] : 'Yorum yok'}",
              style: const TextStyle(fontSize: 15),
            ),
            Text("🌾 Hasat Durumu: $statusText",
                style: TextStyle(fontSize: 15, color: _getStatusColor(statusText))),
            Text("📦 Ürün Miktarı: $amount", style: const TextStyle(fontSize: 15)),
            Text("📏 m² Başına Verim: $yieldText",
                style: TextStyle(fontSize: 15, color: yieldColor)),

            const SizedBox(height: 10),

            // Etiketler
            if (rating['tags'] != null && rating['tags'].isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: List<Widget>.from(
                  (rating['tags'] as List<dynamic>).map((tag) => Chip(label: Text(tag))),
                ),
              ),

            const SizedBox(height: 8),

            // Kategori Bazlı Puanlar
            if (rating['categoryRatings'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("📊 Kategori Puanları:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...((rating['categoryRatings'] as Map<String, dynamic>).entries.map((entry) {
                    return Text("🔸 ${entry.key}: ${entry.value}/5");
                  })),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'çok iyi':
        return Colors.green.shade700;
      case 'iyi':
        return Colors.green;
      case 'normal':
        return Colors.orange;
      case 'kötü':
        return Colors.redAccent;
      case 'çok kötü':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Değerlendirmelerim'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ratings.isEmpty
          ? Center(
          child: Text(errorMessage,
              style:
              const TextStyle(fontSize: 16, color: Colors.red)))
          : ListView.builder(
        itemCount: ratings.length,
        itemBuilder: (context, index) {
          return buildRatingCard(ratings[index]);
        },
      ),
    );
  }
}
