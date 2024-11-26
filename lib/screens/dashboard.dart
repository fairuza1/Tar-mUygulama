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

  Card makeDashboardItem(
      BuildContext context, String title, IconData icon, Widget page) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF87CEEB), // Gökyüzü mavisi
                Color(0xFF228B22), // Doğal yeşil
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5,
                offset: Offset(3, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 50,
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          'Tarım Dashboard',
          style: GoogleFonts.pacifico(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color.fromRGBO(34, 139, 34, 1), // Doğal yeşil
        elevation: 4,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Arka plan
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/dashbord.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black54,
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          // Dashboard içeriği
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
            child: Column(
              children: [
                Text(
                  "Merhaba! Tarım dünyasına hoş geldiniz.",
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      makeDashboardItem(
                          context, "Arazi Ekle", Icons.add_location_alt, AraziEklePage()),
                      makeDashboardItem(
                          context, "Arazilerimi Göster", Icons.map, ArazilerimiGosterPage()),
                      makeDashboardItem(context, "Ekim Yap", Icons.agriculture, EkimYapPage()),
                      makeDashboardItem(context, "Ekimlerimi Göster", Icons.timeline,
                          EkimlerimiGosterPage()),
                      makeDashboardItem(context, "Hasatlarımı Göster", Icons.grass,
                          HasatlarimiGosterPage()),
                      makeDashboardItem(context, "Değerlendirmelerimi Listele", Icons.list_alt,
                          DegerlendirmelerimiListelePage()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
