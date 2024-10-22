import 'package:flutter/material.dart';

class ArazilerimiGosterPage extends StatelessWidget {
  const ArazilerimiGosterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arazilerimi Göster'),
      ),
      body: Center(
        child: const Text('Arazilerimi Göster Sayfası'),
      ),
    );
  }
}
