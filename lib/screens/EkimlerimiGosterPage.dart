import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EkimlerimiGosterPage extends StatefulWidget {
  const EkimlerimiGosterPage({Key? key}) : super(key: key);

  @override
  _EkimlerimiGosterPageState createState() => _EkimlerimiGosterPageState();
}

class _EkimlerimiGosterPageState extends State<EkimlerimiGosterPage> {
  List<dynamic> sowings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSowings();
  }

  Future<void> fetchSowings() async {
    const userId = 1; // Kullanıcının ID'sini dinamik olarak alabilirsiniz
    const String apiUrl = 'http://localhost:8080/api/sowings/user/$userId';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          sowings = json.decode(response.body);
          isLoading = false;
        });
      } else if (response.statusCode == 204) {
        setState(() {
          sowings = [];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load sowings');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching sowings: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ekimlerimi Göster'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sowings.isEmpty
          ? const Center(
        child: Text(
          'Ekim kaydı bulunamadı.',
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: sowings.length,
        itemBuilder: (context, index) {
          final sowing = sowings[index];
          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.grass),
              title: Text('Bitki ID: ${sowing['plantId']}'),
              subtitle: Text(
                'Arazi ID: ${sowing['landId']}\n'
                    'Ekim Tarihi: ${sowing['sowingDate']}',
              ),
              trailing: Text(
                'Miktar: ${sowing['quantity']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}
