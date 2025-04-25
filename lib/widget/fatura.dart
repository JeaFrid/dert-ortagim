import 'package:agor/theme/color.dart';
import 'package:cosmos/cosmos.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FaturaWidget extends StatelessWidget {
  final String amount;
  final String date;
  final String type;
  final String id;

  const FaturaWidget({
    super.key,
    required this.amount,
    required this.date,
    required this.type,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    bool isDeposit = type == "deposit";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDeposit
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDeposit ? Icons.add : Icons.remove,
            color: isDeposit ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          isDeposit ? 'Bakiye Yükleme' : 'Bakiye Kullanımı',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          CosmosTime.getDateTR(CosmosTime.getDateTime(date)),
          style: GoogleFonts.poppins(
            color: textColor.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        trailing: Text(
          '${isDeposit ? '+' : '-'}${amount} TL',
          style: GoogleFonts.poppins(
            color: isDeposit ? Colors.green : Colors.red,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        children: [
          Divider(color: borderColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'İşlem ID',
                style: GoogleFonts.poppins(
                  color: textColorSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                id.substring(0, 8),
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'İşlem Tarihi',
                style: GoogleFonts.poppins(
                  color: textColorSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                CosmosTime.getDateTR(CosmosTime.getDateTime(date)),
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'İşlem Saati',
                style: GoogleFonts.poppins(
                  color: textColorSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                CosmosTime.getDateTime(date)
                    .toString()
                    .split(' ')[1]
                    .substring(0, 5),
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tutar',
                style: GoogleFonts.poppins(
                  color: textColorSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                '${amount} TL',
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Durum',
                style: GoogleFonts.poppins(
                  color: textColorSecondary,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Tamamlandı',
                  style: GoogleFonts.poppins(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
