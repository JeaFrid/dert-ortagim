import 'package:agor/services/database.dart';
import 'package:agor/services/notification_services.dart';
import 'package:agor/theme/color.dart';
import 'package:agor/widget/textfield.dart';
import 'package:cosmos/cosmos.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextEditingController nameIlan = TextEditingController();
TextEditingController aboutIlan = TextEditingController();
String selectedCategory = "Konu Seç";

class AddIlan extends StatefulWidget {
  const AddIlan({super.key});

  @override
  State<AddIlan> createState() => _AddIlanState();
}

class _AddIlanState extends State<AddIlan> {
  final List<String> categories = [
    "İlişki Sorunları",
    "Ayrılık",
    "İş Sorunları",
    "Sinir ve Stres",
    "Aile İçi Sorunlar",
    "Çevre Baskısı",
    "Düşünceler",
    "Maddi Sorunlar",
    "Diğer",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Yeni İlan Oluştur',
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              'İlan Başlığı',
              style: GoogleFonts.poppins(
                color: textColorSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFieldTT(
              text: "Başlık",
              controller: nameIlan,
            ),
            const SizedBox(height: 24),

            // Kategori Seçimi
            Text(
              'Kategori',
              style: GoogleFonts.poppins(
                color: textColorSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCategory,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  dropdownColor: cColor,
                  borderRadius: BorderRadius.circular(12),
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: defaultColor),
                  items: ["Konu Seç", ...categories].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(
                          color: value == "Konu Seç"
                              ? textColorSecondary
                              : textColor,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCategory = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Açıklama
            Text(
              'İlan Açıklaması',
              style: GoogleFonts.poppins(
                color: textColorSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFieldTT(
              text: "Açıklama",
              controller: aboutIlan,
              maxLines: 5,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: defaultColor,
        elevation: 2,
        onPressed: () async {
          if (nameIlan.text.isEmpty ||
              aboutIlan.text.isEmpty ||
              selectedCategory == "Konu Seç") {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: navColor,
                content: Text(
                  'Lütfen tüm alanları doldurun',
                  style: TextStyle(color: textColor),
                ),
              ),
            );
            return;
          }

          String tag = CosmosRandom.randomTag();
          String uid = await CosmosFirebase.getUID();
          await CosmosFirebase.add(
            reference: "ilan",
            tag: tag,
            value: [
              tag,
              uid,
              nameIlan.text,
              aboutIlan.text,
              CosmosTime.getNowTimeString(),
              selectedCategory,
            ],
            onSuccess: () async {
              await NotificationServices.sendNotification(
                userId: uid,
                title: "Yeni İlan",
                message:
                    "\"${nameIlan.text}\" başlıklı ilanınız başarıyla oluşturuldu.",
                type: "ilan",
              );

              nameIlan.clear();
              aboutIlan.clear();
              selectedCategory = "Konu Seç";
              await Database.getIlanlar();
              Navigator.pop(context);
            },
          );
        },
        child: Icon(Icons.check, color: bg, size: 24),
      ),
    );
  }
}
