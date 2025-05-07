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
      body: ListView.builder(
        itemCount: ratings.length,
        itemBuilder: (context, index) {
          final rating = ratings[index];
          return ListTile(
            title: Text('Hasat ID: ${rating['harvestId']}'),
            subtitle: Text('Değerlendirme ID: ${rating['id']}'),
          );
        },
      ),
    );
  }
}
