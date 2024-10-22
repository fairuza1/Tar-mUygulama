import 'package:flutter/material.dart';

class EkimYapPage extends StatelessWidget {
  const EkimYapPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ekim Yap'),
      ),
      body: Center(
        child: const Text('Ekim Yap Sayfası'),
      ),
    );
  }
}
