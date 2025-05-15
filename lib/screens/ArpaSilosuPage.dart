
import 'package:flutter/material.dart';

class ArpaSilosuPage extends StatelessWidget {
  const ArpaSilosuPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Üst yeşil alan
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Geri Butonu
                  Row(
                    children: [
                      Icon(Icons.arrow_back, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Arpa Silosu',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Mahsul - Kilogram',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Toplam Fiyat',
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '15.498,00₺',
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(Icons.delete, 'Ürünü Sil'),
                      _buildActionButton(Icons.edit, 'Ürünü Güncelle'),
                      _buildActionButton(Icons.receipt_long, 'Fiş Al'),
                      _buildActionButton(Icons.share, 'Dışa Aktar'),
                    ],
                  ),
                ],
              ),
            ),

            // "Son İşlemler" başlığı
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Son işlemler',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Icon(Icons.filter_list),
                ],
              ),
            ),

            // Liste
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildTransactionCard(
                    color: Colors.redAccent,
                    title: 'Arpa Çıkışı Yapıldı',
                    date: '15 Nisan 2025',
                    quantity: '150',
                    price: '945,00₺',
                  ),
                  _buildTransactionCard(
                    color: Colors.green,
                    title: 'Arpa Hasadı 2. Kez Geliş',
                    date: '15 Nisan 2025',
                    quantity: '300',
                    price: '5.355,00₺',
                  ),
                  _buildTransactionCard(
                    color: Colors.green,
                    title: 'Arpa Hasadı Mahsulü Alındı',
                    date: '15 Nisan 2025',
                    quantity: '468',
                    price: '4.788,00₺',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white,
          child: Icon(icon, color: Colors.green),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTransactionCard({
    required Color color,
    required String title,
    required String date,
    required String quantity,
    required String price,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(Icons.check, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(date),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Adet: $quantity'),
            Text('Fiyat: $price'),
          ],
        ),
      ),
    );
  }
}
