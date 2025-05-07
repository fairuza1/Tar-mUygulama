import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'screens/DegerlendirPage.dart';
import 'screens/DegerlendirmelerimiListelePage.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Login(),
    routes: {
      '/degerlendirmeler': (context) => const DegerlendirmelerimiListelePage(),
      // Eğer istersen Değerlendir sayfası için de route ekleyebiliriz
    },
  ));
}
