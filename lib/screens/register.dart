import 'dart:convert';
import 'dart:io';
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
        // Hata durumu: Backend'den dönen hata mesajı işleniyor
        var errorResponse = json.decode(res.body);
        if (errorResponse['error'] != null) {
          _showSnackbar(errorResponse['error'], Colors.red);
        } else {
          _showSnackbar("Bir hata oluştu. Lütfen tekrar deneyin.", Colors.red);
        }
      } else {
        // Beklenmeyen hata
        _showSnackbar("Bir hata oluştu. Lütfen tekrar deneyin.", Colors.red);
      }
    } catch (e) {
      print("Hata oluştu: $e");

      if (e is SocketException) {
        print("SocketException: Sunucuya ulaşılamıyor.");
      } else if (e is FormatException) {
        print("FormatException: Beklenmeyen cevap formatı.");
      } else {
        print("Bilinmeyen bir hata: $e");
      }

      _showSnackbar("Sunucuyla iletişim kurulamadı. Lütfen tekrar deneyin.", Colors.red);
    }

  }

  /// Snackbar ile mesaj gösterir.
  void _showSnackbar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
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
                  image: AssetImage('assets/images/farm_background.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.3),
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
