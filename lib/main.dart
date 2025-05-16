import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'screens/DegerlendirmelerimiListelePage.dart';
import 'screens/EkimlerDashboardPage.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Login(),
    routes: {
      '/degerlendirmeler': (context) => const DegerlendirmelerimiListelePage(),
      '/dashboard': (context) => const EkimlerDashboardPage(),
    },
  ));
}
