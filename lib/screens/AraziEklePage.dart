import 'package:flutter/material.dart';

class AraziEklePage extends StatelessWidget {
  const AraziEklePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arazi Ekle'),
      ),
      body: Center(
        child: const Text('Arazi Ekle Sayfası'),
      ),
    );
  }
}
