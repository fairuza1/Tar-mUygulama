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
          ratings = jsonDecode(response.body);
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
            Text(
              "🆔 Değerlendirme ID: ${rating['id']}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              "⭐ Puan: ${rating['rating'] ?? 'Belirtilmemiş'}",
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              "💬 Yorum: ${rating['comment']?.trim().isNotEmpty == true ? rating['comment'] : 'Yorum yok'}",
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              "🌾 Hasat Durumu: $statusText",
              style: TextStyle(
                fontSize: 15,
                color: _getStatusColor(statusText),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "📦 Ürün Miktarı: $amount",
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              "📏 m² Başına Ürün Verimi: $yieldText",
              style: TextStyle(fontSize: 15, color: yieldColor),
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
