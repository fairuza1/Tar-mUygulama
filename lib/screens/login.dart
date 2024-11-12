import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dashboard.dart';
import 'register.dart';
import '../models/user.dart'; // User sınıfını içe aktar

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  User user = User("", ""); // User nesnesini burada oluşturun
  String url = "http://10.0.2.2:8080/login";

  Future<void> save() async {
    var res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': user.email, 'password': user.password}),
    );
    print(res.body);
    if (res.body.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Dashboard(key: UniqueKey()),
        ),
      );
    }
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
                          user.email = val; // User nesnesinin email alanını güncelle
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
                          user.password = val; // User nesnesinin password alanını güncelle
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
