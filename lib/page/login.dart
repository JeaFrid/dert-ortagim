import 'package:agor/controller.dart';
import 'package:agor/page/home.dart';
import 'package:agor/page/register.dart';
import 'package:agor/theme/color.dart';
import 'package:cosmos/cosmos.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widget/textfield.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Giriş yaparak Gizlilik Sözleşmemizi ve KVKK kabul etmiş olursunuz.",
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
                await CosmosFirebase.signIn(
                  email: email.text,
                  password: password.text,
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
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                padding: const EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cColor,
                  borderRadius: BorderRadius.circular(
                    5,
                  ),
                ),
                child: Center(
                  child: Text(
                    "Giriş Yap",
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
                  const RegisterPage(),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                padding: const EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cColor,
                  borderRadius: BorderRadius.circular(
                    5,
                  ),
                ),
                child: Center(
                  child: Text(
                    "Yeni Hesap Oluştur",
                    style: TextStyle(
                      color: textColor.withOpacity(0.3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
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
    );
  }
}
