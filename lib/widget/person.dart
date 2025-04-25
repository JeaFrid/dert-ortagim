import 'dart:async';

import 'package:agor/services/call.dart';
import 'package:agor/services/online.dart';
import 'package:agor/theme/color.dart';
import 'package:agor/page/profile.dart';
import 'package:cosmos/cosmos.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Person extends StatefulWidget {
  final String image;
  final String text;
  final String bio;
  final String uid;
  const Person({
    super.key,
    required this.image,
    required this.text,
    required this.bio,
    required this.uid,
  });

  @override
  State<Person> createState() => _PersonState();
}

class _PersonState extends State<Person> {
  ValueNotifier<bool> isActive = ValueNotifier(false);
  ValueNotifier<String> isCall = ValueNotifier("");

  @override
  void initState() {
    super.initState();
    Future.delayed(
      const Duration(milliseconds: 1),
      () async {
        Map s = await Online.isOnline(widget.uid);
        isActive.value = s["status"];
        isCall.value = s["room"];
        isActive.notifyListeners();
      },
    );
    Timer.periodic(
      const Duration(seconds: 4),
      (timer) async {
        Map s = await Online.isOnline(widget.uid);
        isActive.value = s["status"];
        isCall.value = s["room"];
        isActive.notifyListeners();
      },
    );
  }

  void _showUserOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: defaultColor.withOpacity(0.1),
                backgroundImage: NetworkImage(widget.image),
                child: widget.image.isEmpty
                    ? Icon(Icons.person, size: 40, color: defaultColor)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                widget.text,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.bio,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: textColorSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              _buildOptionButton(
                icon: Icons.call,
                text: 'Dinleyiciyi Ara',
                onTap: () {
                  Navigator.pop(context);
                  if (isCall.value == "-1") {
                    CallClass.addCall(context, widget.uid);
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildOptionButton(
                icon: Icons.person_outline,
                text: 'Dinleyici Profili',
                onTap: () {
                  Navigator.pop(context);
                  CosmosNavigator.pushNonAnimated(
                    context,
                    Profile(uid: widget.uid),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildOptionButton(
                icon: Icons.copy,
                text: 'Dinleyici ID Kopyala',
                onTap: () {
                  Navigator.pop(context);
                  copy(widget.uid);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: navColor,
                      content: Text(
                        'ID kopyalandı',
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: defaultColor, size: 20),
              const SizedBox(width: 12),
              Text(
                text,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
    return ListenableBuilder(
      listenable: Listenable.merge([isActive, isCall]),
      builder: (context, child) {
        return Visibility(
          visible: (isCall.value == "0"
                      ? isActive.value == true
                          ? "Aktif"
                          : "Çevrimdışı"
                      : isCall.value == "-1"
                          ? "Müsait"
                          : "Konuşmada") ==
                  "Müsait"
              ? true
              : false,
          child: GestureDetector(
            onTap: () => _showUserOptions(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: cColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: defaultColor.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        widget.image,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 50,
                          height: 50,
                          color: defaultColor.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            color: defaultColor,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.text,
                                style: GoogleFonts.poppins(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: defaultColor.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isCall.value == "0"
                                    ? isActive.value == true
                                        ? "Aktif"
                                        : "Çevrimdışı"
                                    : isCall.value == "-1"
                                        ? "Müsait"
                                        : "Konuşmada",
                                style: GoogleFonts.poppins(
                                  color: isActive.value == true
                                      ? defaultColor
                                      : textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.bio,
                          style: GoogleFonts.poppins(
                            color: textColorSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
