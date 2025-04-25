import 'package:agor/services/database.dart';
import 'package:agor/theme/color.dart';
import 'package:cosmos/cosmos.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  ValueNotifier<List<Map<String, dynamic>>> reviews = ValueNotifier([]);
  ValueNotifier<Map<String, dynamic>> stats = ValueNotifier({
    "totalReviews": 0,
    "averageRating": 0.0,
    "totalCalls": 0,
    "totalCallDuration": 0,
  });

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadCallStats();
  }

  Future<void> _loadReviews() async {
    try {
      String uid = await CosmosFirebase.getUID();
      List reviewData = await CosmosFirebase.getOnce("reviews/$uid");
      List<Map<String, dynamic>> loadedReviews = [];
      int totalRating = 0;

      for (var review in reviewData) {
        if (review is List && review.length >= 5) {
          int rating = int.tryParse(review[2]) ?? 0;
          Map<String, dynamic> reviewMap = {
            "id": review[0],
            "reviewer": review[1],
            "rating": rating,
            "comment": review[3],
            "time": review[4],
          };

          loadedReviews.add(reviewMap);
          totalRating += rating;
        }
      }

      reviews.value = loadedReviews;

      // İstatistikleri güncelle
      stats.value["totalReviews"] = loadedReviews.length;
      stats.value["averageRating"] = loadedReviews.isEmpty
          ? 0.0
          : (totalRating / loadedReviews.length).toDouble();

      reviews.notifyListeners();
      stats.notifyListeners();
    } catch (e) {
      reviews.value = [];
      reviews.notifyListeners();
      print("Değerlendirme yüklenirken hata: $e");
    }
  }

  Future<void> _loadCallStats() async {
    try {
      String uid = await CosmosFirebase.getUID();
      List callData = await CosmosFirebase.getOnce("callHistory/$uid");

      int totalCalls = callData.length;
      int totalDuration = 0;

      for (var call in callData) {
        if (call is List && call.length >= 3) {
          int duration = int.tryParse(call[2]) ?? 0;
          totalDuration += duration;
        }
      }

      stats.value["totalCalls"] = totalCalls;
      stats.value["totalCallDuration"] = totalDuration;
      stats.notifyListeners();
    } catch (e) {
      print("Arama istatistikleri yüklenirken hata: $e");
    }
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
          'İstatistiklerim',
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 18,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([reviews, stats]),
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Özet Kartları
                _buildSummaryCards(),

                const SizedBox(height: 24),

                // Değerlendirmeler Başlığı
                Text(
                  'Değerlendirmelerim',
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Değerlendirmeler Listesi
                if (reviews.value.isEmpty)
                  _buildEmptyReviewsCard()
                else
                  ...reviews.value.map((review) => _buildReviewItem(
                        review["comment"],
                        review["rating"],
                        CosmosTime.getDateTR(
                          CosmosTime.getDateTime(review["time"]),
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam Değerlendirme',
                '${stats.value["totalReviews"]}',
                Icons.star_rate,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Ortalama Puan',
                '${stats.value["averageRating"].toStringAsFixed(1)}',
                Icons.thumb_up,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam Görüşme',
                '${stats.value["totalCalls"]}',
                Icons.call,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Toplam Süre',
                '${_formatDuration(stats.value["totalCallDuration"])}',
                Icons.timer,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours saat ${minutes > 0 ? '$minutes dk' : ''}';
    } else {
      return '$minutes dakika';
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: defaultColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: textColorSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReviewsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            color: defaultColor.withOpacity(0.5),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz Değerlendirme Yok',
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kullanıcılar sizi değerlendirdiğinde burada görünecek.',
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

  Widget _buildReviewItem(String comment, int rating, String time) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                5,
                (index) => Icon(
                  Icons.star,
                  size: 16,
                  color: index < rating
                      ? Colors.amber
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: GoogleFonts.poppins(
                  color: textColor.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
