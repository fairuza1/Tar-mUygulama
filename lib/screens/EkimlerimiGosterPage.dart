import 'package:flutter/material.dart';

class EkimlerimiGosterPage extends StatelessWidget {
  const EkimlerimiGosterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ekimlerimi Göster'),
      ),
      body: Center(
        child: const Text('Ekimlerimi Göster Sayfası'),
      ),
    );
  }
}
