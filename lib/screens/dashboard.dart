import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'AraziEklePage.dart';
import 'ArazilerimiGosterPage.dart';
import 'EkimYapPage.dart';
import 'EkimlerimiGosterPage.dart';
import 'HasatlarimiGosterPage.dart';
import 'DegerlendirmelerimiListelePage.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({Key? key}) : super(key: key);

  Card makeDashboardItem(BuildContext context, String title, IconData icon, Widget page) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF004B8D),
                Color(0xFFffffff),
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.grey,
                blurRadius: 3,
                offset: Offset(2, 2),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Icon(
                icon,
                size: 50,
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: GoogleFonts.roboto(),
        ),
        backgroundColor: const Color.fromRGBO(233, 65, 82, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(2),
                children: [
                  makeDashboardItem(context,"Arazi Ekle", Icons.add, AraziEklePage()),
                  makeDashboardItem(context,"Arazilerimi Göster", Icons.list, ArazilerimiGosterPage()),
                  makeDashboardItem(context,"Ekim Yap", Icons.agriculture, EkimYapPage()),
                  makeDashboardItem(context,"Ekimlerimi Göster", Icons.replay, EkimlerimiGosterPage()),
                  makeDashboardItem(context,"Hasatlarımı Göster", Icons.grass, HasatlarimiGosterPage()),
                  makeDashboardItem(context,"Değerlendirmelerimi Listele", Icons.list_alt, DegerlendirmelerimiListelePage()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
