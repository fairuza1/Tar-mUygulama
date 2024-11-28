import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  User user = User("", "");
  String url = "http://10.0.2.2:8080/users/register"; // Yerel sunucu adresi

  /// Kullanıcı kaydını backend'e gönderir ve sonucu işleyerek ekrana mesaj gösterir.
  Future<void> save() async {
    try {
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': user.email, 'password': user.password}),
      );

      print("Status Code: ${res.statusCode}");
      print("Response Body: ${res.body}");

      if (res.statusCode == 201) {
        // Kayıt başarılı
        _showSnackbar("Kayıt başarıyla tamamlandı!", Colors.green);
        Navigator.pop(context);
      } else if (res.statusCode == 400) {
        // Eğer yanıt düz metinse, JSON çözmeden doğrudan yazdırın
        String errorMessage = res.body; // Burada doğrudan body'yi alıyoruz
        print("Error Message: $errorMessage");
        _showSnackbar(errorMessage, Colors.red);
      } else if (res.statusCode == 409) {
        // E-posta zaten kayıtlı ise
        _showSnackbar("Bu e-posta adresi zaten kayıtlı.", Colors.red);
      } else {
        // Beklenmeyen hata
        print("Beklenmeyen hata: ${res.statusCode}");
        _showSnackbar("Bir hata oluştu. Lütfen tekrar deneyin.", Colors.red);
      }
    } catch (e) {
      print("Error: $e");
      _showSnackbar("Sunucuya ulaşılamıyor. Lütfen bağlantınızı kontrol edin.", Colors.red);
    }
  }


  /// Snackbar ile mesaj gösterir.
  void _showSnackbar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: GoogleFonts.roboto(color: Colors.white),
      ),
      backgroundColor: color,
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Arka plan görseli
            Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/farm_background.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Color(0xFF000000).withOpacity(0.3),  // Düzeltilmiş satır
                    BlendMode.darken,
                  ),
                ),
              ),
            ),

            // Form içeriği
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  Text(
                    "Kayıt Ol",
                    style: GoogleFonts.pacifico(
                      fontWeight: FontWeight.bold,
                      fontSize: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 50),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("E-posta"),
                        _buildTextField(
                          onChanged: (val) => user.email = val,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen e-posta adresinizi giriniz.';
                            }
                            if (!RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value)) {
                              return 'Geçerli bir e-posta adresi giriniz.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        _buildLabel("Şifre"),
                        _buildTextField(
                          obscureText: true,
                          onChanged: (val) => user.password = val,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen bir şifre giriniz.';
                            }
                            if (value.length < 6) {
                              return 'Şifreniz en az 6 karakter olmalıdır.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 50),
                        Center(
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Hesabınız var mı? Giriş yapın!",
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(34, 139, 34, 1), // Doğal bir yeşil
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 50,
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          save();
                        }
                      },
                      child: const Text(
                        "Kayıt Ol",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required Function(String) onChanged,
    required String? Function(String?) validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      obscureText: obscureText,
      style: const TextStyle(fontSize: 18, color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white30,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
      ),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
