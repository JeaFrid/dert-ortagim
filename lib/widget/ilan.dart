import 'dart:async';
import 'package:agor/services/online.dart';
import 'package:agor/theme/color.dart';
import 'package:cosmos/cosmos.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/call.dart';

class Ilan extends StatefulWidget {
  final String text;
  final String bio;
  final String time;
  final String name;
  final String id;
  final String uid;
  const Ilan({
    super.key,
    required this.text,
    required this.bio,
    required this.id,
    required this.time,
    required this.uid,
    required this.name,
  });

  @override
  State<Ilan> createState() => _IlanState();
}

class _IlanState extends State<Ilan> {
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
        isCall.notifyListeners();
      },
    );
    Timer.periodic(
      const Duration(seconds: 4),
      (timer) async {
        Map s = await Online.isOnline(widget.uid);
        isActive.value = s["status"];
        isCall.value = s["room"];
        isCall.notifyListeners();
        isActive.notifyListeners();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        isCall,
        isActive,
      ]),
      builder: (context, child) {
        return GestureDetector(
          onTap: () async {
            if (isCall.value == "-1") {
              await CallClass.addCall(context, widget.uid);
            }
          },
          child: Container(
            width: width(context),
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
                color: cColor,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: defaultColor.withOpacity(0.4),
                    blurRadius: 3,
                    offset: const Offset(1, 2),
                  ),
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: defaultColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
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
                            : textColor.withAlpha(100),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  widget.name,
                  style: GoogleFonts.poppins(
                    color: textColor.withAlpha(200),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.time,
                  style: GoogleFonts.poppins(
                    color: textColor.withAlpha(100),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  widget.bio,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: textColor.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
