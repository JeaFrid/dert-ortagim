import 'package:agor/controller.dart';
import 'package:agor/page/home.dart';
import 'package:agor/page/login.dart';
import 'package:agor/theme/color.dart';
import 'package:agor/widget/textfield.dart';
import 'package:cosmos/cosmos.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String selectedGender = 'Erkek';
  String selectedUserType = 'Dinleyici';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Text(
                "Dert Ortağım",
                style: GoogleFonts.poppins(
                  color: defaultColor,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFieldTT(
                text: "Kullanıcı Adı",
                controller: username,
                keyboardType: TextInputType.name,
              ),
              TextFieldTT(
                text: "E-Posta",
                controller: email,
                keyboardType: TextInputType.emailAddress,
              ),
              TextFieldTT(
                text: "Parola",
                controller: password,
                keyboardType: TextInputType.visiblePassword,
              ),
              const SizedBox(height: 10),
              // Cinsiyet Seçimi
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: cColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: DropdownButton<String>(
                  value: selectedGender,
                  isExpanded: true,
                  dropdownColor: cColor,
                  style: TextStyle(color: textColor),
                  underline: const SizedBox(),
                  items: ['Erkek', 'Kadın'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedGender = newValue!;
                    });
                  },
                ),
              ),
              // Kullanıcı Tipi Seçimi
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: cColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: DropdownButton<String>(
                  value: selectedUserType,
                  isExpanded: true,
                  dropdownColor: cColor,
                  style: TextStyle(color: textColor),
                  underline: const SizedBox(),
                  items: ['Dinleyici', 'Anlatıcı'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedUserType = newValue!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Kayıt olarak Gizlilik Sözleşmemizi ve KVKK kabul etmiş olursunuz.",
                        style: TextStyle(
                          color: textColor.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  int id = CosmosRandom.string(10).hashCode.abs() % 100000;
                  await CosmosFirebase.signUp(
                    email: email.text,
                    password: password.text,
                    userDatas: [
                      username.text,
                      email.text,
                      password.text,
                      "", // Profil Fotoğrafı
                      "Merhaba dünya!", //Biyografi
                      CosmosTime.getNowTimeString(),
                      id, //sesli konuşma id'si
                      selectedGender, // Cinsiyet
                      selectedUserType, // Kullanıcı tipi
                      "0", // Tatil modu (0: kapalı, 1: açık)
                      "0", // Cüzdan bakiyesi
                    ],
                    trError: true,
                    onError: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: navColor,
                          content: Text(
                            error,
                            style: TextStyle(
                              color: textColor,
                            ),
                          ),
                        ),
                      );
                    },
                    onSuccess: () {
                      CosmosNavigator.pushNonAnimated(
                        context,
                        const HomePage(),
                      );
                    },
                  );
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      "Kayıt Ol",
                      style: TextStyle(
                        color: defaultColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "VEYA",
                  style: TextStyle(
                    color: textColor.withOpacity(0.4),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  CosmosNavigator.pushNonAnimated(
                    context,
                    const LoginPage(),
                  );
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      "Varolan Hesaba Giriş Yap",
                      style: TextStyle(
                        color: textColor.withOpacity(0.3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Dert Ortağım | 2025",
                style: TextStyle(
                  color: textColor.withOpacity(0.3),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
