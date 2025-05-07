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

  @override
  void initState() {
    super.initState();
    fetchRatings();
  }

  Future<void> fetchRatings() async {
    final url = Uri.parse('http://10.0.2.2:8080/api/ratings'); // Emülatör için uygun

    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        ratings = jsonDecode(response.body);
      });
    } else {
      // hata durumu
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Değerlendirmeler alınamadı")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Değerlendirmelerimi Listele'),
        backgroundColor: Colors.green,
      ),
      body: ratings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: ratings.length,
        itemBuilder: (context, index) {
          final rating = ratings[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            elevation: 4,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              title: Text('Hasat ID: ${rating['harvestId']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Değerlendirme ID: ${rating['id']}'),
                  Text('Puan: ${rating['rating']}'),
                  Text('Yorum: ${rating['comment'] ?? 'Yorum yok'}'),
                  Text('Hasat Durumu: ${rating['harvestStatus'] ?? 'Durum belirtilmemiş'}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
