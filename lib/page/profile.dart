import 'dart:async';

import 'package:agor/services/database.dart';
import 'package:agor/services/notification_services.dart';
import 'package:agor/services/online.dart';
import 'package:agor/theme/color.dart';
import 'package:cosmos/cosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class Profile extends StatefulWidget {
  final String? uid;
  const Profile({super.key, this.uid});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  ValueNotifier<bool> isActive = ValueNotifier(false);
  ValueNotifier<String> isCall = ValueNotifier("");
  ValueNotifier<int> selectedRating = ValueNotifier(0);
  ValueNotifier<List<Map<String, dynamic>>> reviews = ValueNotifier([]);
  ValueNotifier<Map<String, dynamic>?> myReview = ValueNotifier(null);
  TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadReviews();
    Future.delayed(
      const Duration(milliseconds: 1),
      () async {
        Map s = await Online.isOnline(widget.uid ?? Database.profileUID.value);
        isActive.value = s["status"];
        isCall.value = s["room"];
        isActive.notifyListeners();
      },
    );
    Timer.periodic(
      const Duration(seconds: 4),
      (timer) async {
        Map s = await Online.isOnline(widget.uid ?? Database.profileUID.value);
        isActive.value = s["status"];
        isCall.value = s["room"];
        isActive.notifyListeners();
      },
    );
  }

  Future<void> _loadProfile() async {
    await Database.getMyProfile(id: widget.uid);

    // Eğer başka birinin profili ziyaret ediliyorsa ve bu kişi dinleyici ise bildirim gönder
    if (widget.uid != null &&
        Database.profileUserTypeYou.value == "Dinleyici") {
      String myUid = await CosmosFirebase.getUID();

      // Profil ziyareti bildirimi gönder
      await NotificationServices.sendNotification(
        userId: widget.uid!,
        title: "Profil Ziyareti",
        message: "${Database.profileName.value} profilinizi ziyaret etti",
        type: "profile",
      );
    }
  }

  Future<void> _loadReviews() async {
    if (widget.uid != null) {
      try {
        List reviewData = await CosmosFirebase.getOnce("reviews/${widget.uid}");
        List<Map<String, dynamic>> loadedReviews = [];
        String myUid = await CosmosFirebase.getUID();
        Map<String, dynamic>? userReview;

        for (var review in reviewData) {
          if (review is List && review.length >= 5) {
            Map<String, dynamic> reviewMap = {
              "id": review[0],
              "reviewer": review[1],
              "rating": int.tryParse(review[2]) ?? 0,
              "comment": review[3],
              "time": review[4],
            };

            loadedReviews.add(reviewMap);

            // Kullanıcının kendi değerlendirmesini kontrol et
            if (review[1] == myUid) {
              userReview = reviewMap;
              // Eğer kullanıcının değerlendirmesi varsa, form alanlarını doldur
              selectedRating.value = reviewMap["rating"];
              commentController.text = reviewMap["comment"];
            }
          }
        }

        reviews.value = loadedReviews;
        myReview.value = userReview;
        reviews.notifyListeners();
        myReview.notifyListeners();
      } catch (e) {
        // Eğer reviews koleksiyonu yoksa veya boşsa, boş liste kullan
        reviews.value = [];
        myReview.value = null;
        reviews.notifyListeners();
        myReview.notifyListeners();
        print("Değerlendirme yüklenirken hata: $e");
      }
    }
  }

  Future<void> _submitReview() async {
    if (widget.uid != null && commentController.text.isNotEmpty) {
      String myUid = await CosmosFirebase.getUID();
      String time = CosmosTime.getNowTimeString();
      String reviewId = DateTime.now().millisecondsSinceEpoch.toString();

      // Eğer kullanıcı daha önce değerlendirme yapmışsa, güncelle
      if (myReview.value != null) {
        await CosmosFirebase.add(
            reference: "reviews/${widget.uid}",
            tag: myReview.value!["id"],
            value: [
              myReview.value!["id"],
              myUid,
              selectedRating.value.toString(),
              commentController.text,
              time
            ]);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: defaultColor,
            content: Text(
              'Değerlendirmeniz güncellendi',
              style: TextStyle(color: bg),
            ),
          ),
        );

        // Değerlendirme güncellendiğinde bildirim gönder
        await NotificationServices.sendReviewNotification(
          userId: widget.uid!,
          reviewerName: Database.profileName.value,
          rating: selectedRating.value,
        );
      } else {
        // Yeni değerlendirme ekle
        await CosmosFirebase.add(
            reference: "reviews/${widget.uid}",
            tag: reviewId,
            value: [
              reviewId,
              myUid,
              selectedRating.value.toString(),
              commentController.text,
              time
            ]);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: defaultColor,
            content: Text(
              'Değerlendirmeniz gönderildi',
              style: TextStyle(color: bg),
            ),
          ),
        );

        // Yeni değerlendirme yapıldığında bildirim gönder
        await NotificationServices.sendReviewNotification(
          userId: widget.uid!,
          reviewerName: Database.profileName.value,
          rating: selectedRating.value,
        );
      }

      await _loadReviews();
    }
  }

  void _reportUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cColor,
        title: Text(
          'Kullanıcıyı Şikayet Et',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              maxLines: 5,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Şikayet nedeninizi yazın...',
                hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                filled: true,
                fillColor: bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: defaultColor,
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: defaultColor,
                  content: Text(
                    'Şikayetiniz alındı. En kısa sürede incelenecektir.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
            child: Text(
              'Gönder',
              style: TextStyle(color: Colors.white),
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
          'Profil',
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 18,
          ),
        ),
        actions: [
          if (widget.uid != null) ...[
            IconButton(
              icon: Icon(Icons.copy, color: defaultColor.withOpacity(0.7)),
              onPressed: () {
                Clipboard.setData(ClipboardData(
                    text: widget.uid ?? Database.profileUID.value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: defaultColor,
                    content: Text(
                      'Kullanıcı ID kopyalandı',
                      style: TextStyle(color: bg),
                    ),
                  ),
                );
              },
              tooltip: 'Kullanıcı ID\'yi kopyala',
            ),
            IconButton(
              icon: Icon(Icons.report_problem_outlined, color: Colors.red[300]),
              onPressed: _reportUser,
              tooltip: 'Şikayet Et',
            ),
          ],
        ],
      ),
      body: ListenableBuilder(
          listenable: Listenable.merge([
            Database.profileNameYou,
            Database.profilePhotoYou,
            Database.profileBioYou,
            Database.profileUserTypeYou,
            Database.profileGenderYou,
            Database.profileTimeYou,
            Database.profileUIDYou,
            selectedRating,
            reviews,
            myReview,
          ]),
          builder: (context, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: defaultColor.withOpacity(0.1),
                    backgroundImage: NetworkImage(
                      widget.uid == null
                          ? Database.profilePhoto.value
                          : Database.profilePhotoYou.value,
                    ),
                    child: (widget.uid == null
                                ? Database.profilePhoto.value
                                : Database.profilePhotoYou.value)
                            .isEmpty
                        ? Icon(Icons.person, size: 50, color: defaultColor)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.uid == null
                            ? Database.profileName.value
                            : Database.profileNameYou.value,
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: defaultColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.uid == null
                          ? Database.profileUserType.value
                          : Database.profileUserTypeYou.value,
                      style: GoogleFonts.poppins(
                        color: defaultColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biyografi',
                          style: GoogleFonts.poppins(
                            color: defaultColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.uid == null
                              ? Database.profileBio.value
                              : Database.profileBioYou.value,
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hesap Bilgileri',
                          style: GoogleFonts.poppins(
                            color: defaultColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'Cinsiyet',
                          widget.uid == null
                              ? Database.profileGender.value
                              : Database.profileGenderYou.value,
                        ),
                        _buildInfoRow(
                          'Katılma Tarihi',
                          CosmosTime.getDateTR(
                            CosmosTime.getDateTime(
                              widget.uid == null
                                  ? Database.profileTime.value
                                  : Database.profileTimeYou.value,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sadece başkasının profilinde ve dinleyici ise puan verme bölümünü göster
                  if (widget.uid != null &&
                      (Database.profileUserTypeYou.value == "Dinleyici")) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            myReview.value != null
                                ? 'Değerlendirmenizi Düzenleyin'
                                : 'Değerlendirme Yap',
                            style: GoogleFonts.poppins(
                              color: defaultColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () {
                                  selectedRating.value = index + 1;
                                  selectedRating.notifyListeners();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 12),
                                  child: Icon(
                                    Icons.star,
                                    size: 36,
                                    color: index < selectedRating.value
                                        ? Colors.amber
                                        : Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: commentController,
                            maxLines: 3,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: 'Yorumunuzu yazın...',
                              hintStyle:
                                  TextStyle(color: textColor.withOpacity(0.5)),
                              filled: true,
                              fillColor: bg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: defaultColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitReview,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: defaultColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                myReview.value != null
                                    ? 'Değerlendirmeyi Güncelle'
                                    : 'Değerlendirmeyi Gönder',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Değerlendirmeler bölümü
                  if (widget.uid != null &&
                      (Database.profileUserTypeYou.value == "Dinleyici")) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Değerlendirmeler',
                            style: GoogleFonts.poppins(
                              color: defaultColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (reviews.value.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Henüz değerlendirme yapılmamış',
                                  style: GoogleFonts.poppins(
                                    color: textColor.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...reviews.value.map((review) => _buildReviewItem(
                                  review["comment"],
                                  review["rating"],
                                  CosmosTime.getDateTR(
                                    CosmosTime.getDateTime(review["time"]),
                                  ),
                                  review["reviewer"] ==
                                      (myReview.value?["reviewer"] ?? ""),
                                )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColorSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(
      String comment, int rating, String time, bool isMyReview) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: 0.5,
          ),
        ),
        color: isMyReview ? defaultColor.withOpacity(0.05) : null,
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
              const SizedBox(width: 8),
              Text(
                time,
                style: GoogleFonts.poppins(
                  color: textColor.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              if (isMyReview) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: defaultColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Sizin',
                    style: GoogleFonts.poppins(
                      color: defaultColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
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
