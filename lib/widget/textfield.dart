import 'package:agor/theme/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class TextFieldTT extends StatefulWidget {
  final String text;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool? readOnly;
  final bool? obscureText;

  final List<TextInputFormatter>? inputFormatters;
  const TextFieldTT({
    super.key,
    required this.text,
    required this.controller,
    this.keyboardType,
    this.maxLines,
    this.inputFormatters,
    this.readOnly,
    this.obscureText,
  });

  @override
  State<TextFieldTT> createState() => _TextFieldTTState();
}

class _TextFieldTTState extends State<TextFieldTT> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
      child: TextField(
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        obscureText: widget.obscureText ?? false,
        readOnly: widget.readOnly ?? false,
        inputFormatters: widget.inputFormatters,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w400,
        ),
        cursorColor: defaultColor,
        controller: widget.controller,
        decoration: InputDecoration(
          hintStyle: TextStyle(
            color: textColor.withOpacity(0.5),
            fontWeight: FontWeight.w400,
          ),
          hintText: widget.text,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: defaultColor.withOpacity(0.4),
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: defaultColor.withOpacity(0.4),
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: defaultColor.withOpacity(0.8),
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: defaultColor.withOpacity(0.4),
              width: 2,
            ),
          ),
          isDense: true,
        ),
      ),
    );
  }
}
