// degerlendir_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DegerlendirPage extends StatelessWidget {
  final Map<String, dynamic> harvest;

  const DegerlendirPage({Key? key, required this.harvest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hasat Değerlendirme', style: GoogleFonts.notoSans()),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Hasat ID: ${harvest['id']}\n'
              'Bitki: ${harvest['plantName']}\n'
              'Kategori: ${harvest['categoryName']}\n'
              'Ekim Miktarı: ${harvest['plantingAmount']}\n',
          style: GoogleFonts.notoSans(fontSize: 16),
        ),
      ),
    );
  }
}
