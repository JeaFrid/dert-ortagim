import 'package:agor/services/database.dart';
import 'package:agor/theme/color.dart';
import 'package:agor/widget/person.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryContentPage extends StatefulWidget {
  final String category;
  const CategoryContentPage({super.key, required this.category});

  @override
  State<CategoryContentPage> createState() => _CategoryContentPageState();
}

class _CategoryContentPageState extends State<CategoryContentPage> {
  List<Person> listeners = [];

  @override
  void initState() {
    super.initState();
    _loadListeners();
  }

  Future<void> _loadListeners() async {
    final categoryListeners =
        await Database.getCategoryListeners(widget.category);
    setState(() {
      listeners = categoryListeners;
    });
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.volume_off_outlined,
            color: defaultColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Buralar çok sessiz...',
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Şu an bu kategoride hiçbir dinleyici bulunmuyor.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: textColorSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

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
          widget.category,
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 18,
          ),
        ),
      ),
      body: ValueListenableBuilder<Map<String, int>>(
        valueListenable: Database.activeCategoryListeners,
        builder: (context, categoryCount, child) {
          final count = categoryCount[widget.category] ?? 0;
          if (count == 0) {
            return Center(child: _buildEmptyState());
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listeners.length,
            itemBuilder: (context, index) {
              return listeners[index];
            },
          );
        },
      ),
    );
  }
}
