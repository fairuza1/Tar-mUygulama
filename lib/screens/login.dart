import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dashboard.dart';
import 'register.dart';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences'i içe aktar
import '../models/user.dart'; // User sınıfını içe aktar

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  User user = User("", ""); // User nesnesini burada oluşturun
  String url = "http://10.0.2.2:8080/users/login";

  // Kullanıcıyı giriş işlemi ve ID'yi kaydetme
  // Kullanıcıyı giriş işlemi ve ID'yi kaydetme
  Future<void> save() async {
    var res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': user.email, 'password': user.password}),
    );

    // Debugging: Ham JSON verisini yazdırma
    print('Raw response body: ${res.body}');

    try {
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        var responseData = json.decode(res.body); // JSON çözümlemesi

        // Debugging: Çözümlenen veriyi yazdırma
        print('Decoded response: $responseData');

        // Gelen yanıt içerisinde userId'yi al
        int userId = responseData['id']; // Örneğin 'id' alanını kullanın

        // Kullanıcı ID'sini konsola yazdır
        print('Giriş yapan kullanıcının ID\'si: $userId');

        // SharedPreferences'a userId'yi kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', userId);

        // Kullanıcıyı Dashboard'a yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Dashboard(key: UniqueKey()),
          ),
        );
      } else {
        _showSnackbar('Giriş başarısız', Colors.red);
      }
    } catch (e) {
      print('Error parsing JSON: $e');
      _showSnackbar('Veri işlenirken bir hata oluştu', Colors.red);
    }
  }


  void _showSnackbar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                height: 700,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(233, 65, 82, 1),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black,
                      offset: const Offset(1, 5),
                    )
                  ],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(80),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 100),
                      Text(
                        "Login",
                        style: GoogleFonts.pacifico(
                          fontWeight: FontWeight.bold,
                          fontSize: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          "E-mail",
                          style: GoogleFonts.roboto(
                            fontSize: 40,
                            color: const Color.fromRGBO(255, 255, 255, 0.8),
                          ),
                        ),
                      ),
                      TextFormField(
                        onChanged: (val) {
                          user.email = val;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'E-mail Boş girdiniz ';
                          }
                          return null;
                        },
                        style: const TextStyle(fontSize: 30, color: Colors.white),
                        decoration: const InputDecoration(
                          errorStyle: TextStyle(fontSize: 20, color: Colors.black),
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                        ),
                      ),
                      Container(
                        height: 8,
                        color: const Color.fromRGBO(255, 255, 255, 0.4),
                      ),
                      const SizedBox(height: 60),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          "Şifre",
                          style: GoogleFonts.roboto(
                            fontSize: 40,
                            color: const Color.fromRGBO(255, 255, 255, 0.8),
                          ),
                        ),
                      ),
                      TextFormField(
                        obscureText: true,
                        onChanged: (val) {
                          user.password = val;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Şifre boş girdiniz';
                          }
                          return null;
                        },
                        style: const TextStyle(fontSize: 30, color: Colors.white),
                        decoration: const InputDecoration(
                          errorStyle: TextStyle(fontSize: 20, color: Colors.black),
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                        ),
                      ),
                      Container(
                        height: 8,
                        color: const Color.fromRGBO(255, 255, 255, 0.4),
                      ),
                      const SizedBox(height: 60),
                      Center(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Register(),
                              ),
                            );
                          },
                          child: Text(
                            "Hesabınız Yok İse Kayıt Olun ",
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                height: 90,
                width: 90,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: const Color.fromRGBO(233, 65, 82, 1),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      save();
                    }
                  },
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
