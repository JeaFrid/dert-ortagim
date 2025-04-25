import 'dart:async';

import 'package:agor/controller/controller.dart';
import 'package:agor/page/add_ilan.dart';
import 'package:agor/page/category_content.dart';
import 'package:agor/page/edit_profile.dart';
import 'package:agor/page/login.dart';
import 'package:agor/page/notifications.dart';
import 'package:agor/page/profile.dart';
import 'package:agor/page/wallet.dart';
import 'package:agor/page/statistics.dart';
import 'package:agor/services/call.dart';
import 'package:agor/services/database.dart';
import 'package:agor/services/online.dart';
import 'package:agor/theme/color.dart';
import 'package:cosmos/cosmos.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ValueNotifier<String> status = ValueNotifier("-1");

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(
      const Duration(milliseconds: 1),
      () async {
        await Online.meOnline(room: status.value);
        await Database.getUsers();
        await Database.getMyProfile();
        await Database.getIlanlar();
        await Database.updateActiveCategoryListeners();

        Timer.periodic(
          const Duration(seconds: 5),
          (timer) async {
            await Online.meOnline(room: status.value);
            await Database.updateActiveCategoryListeners();
          },
        );
      },
    );
    CosmosFirebase.dataChanged(
      reference: "call",
      onDataChanged: (element) async {
        List ele = element as List;
        bool x = isTimeDMT59s(ele[5], CosmosTime.getNowTimeString());

        if (Database.profileUID.value == ele[2]) {
          if (!x && ele[3] == "0") {
            List o = await CosmosFirebase.get('users/"${ele[1]}"', true);
            await CallClass.updateCall(context, ele[0], 1);
            CosmosAlert.showCustomAlert(
              context,
              Center(
                child: IntrinsicHeight(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    width: width(context) * 0.9,
                    decoration: BoxDecoration(
                      color: cColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        ClipOval(
                          child: Image.network(
                            o[3],
                            width: 50,
                            height: 50,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                "assets/user.png",
                                width: 50,
                                height: 50,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                o[0],
                                style: GoogleFonts.poppins(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Arıyor...",
                                style: GoogleFonts.poppins(
                                  color: textColor.withOpacity(0.4),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            Navigator.pop(context);
                            await CallClass.updateCall(context, ele[0], 3);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                            child: Icon(
                              Icons.call,
                              size: 16,
                              color: bg,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () async {
                            Navigator.pop(context);
                            await CallClass.updateCall(context, ele[0], 2);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red[800],
                            ),
                            child: Icon(
                              Icons.call_end,
                              size: 16,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([homeUsers, homeIlanlar]),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: bg,
          floatingActionButton: FloatingActionButton(
            heroTag: "add",
            backgroundColor: defaultColor,
            elevation: 2,
            onPressed: () {
              CosmosNavigator.pushNonAnimated(context, const AddIlan());
            },
            child: Icon(Icons.add, color: bg, size: 24),
          ),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  backgroundColor: bg,
                  floating: true,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  title: Row(
                    children: [
                      Text(
                        "Dert Ortağım",
                        style: GoogleFonts.poppins(
                          color: defaultColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            CosmosNavigator.pushNonAnimated(
                              context,
                              const WalletPage(),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: cColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.account_balance_wallet,
                                    color: defaultColor, size: 20),
                                const SizedBox(width: 4),
                                ValueListenableBuilder<String>(
                                  valueListenable: Database.profileWallet,
                                  builder: (context, value, child) {
                                    return Text(
                                      value,
                                      style: GoogleFonts.poppins(
                                        color: defaultColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            CosmosNavigator.pushNonAnimated(
                              context,
                              const NotificationsPage(),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: cColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderColor,
                              ),
                            ),
                            child: Icon(Icons.notifications,
                                color: defaultColor, size: 20),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: cColor,
                                title: Text(
                                  'Ayarlar',
                                  style: GoogleFonts.poppins(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading:
                                          Icon(Icons.edit, color: defaultColor),
                                      title: Text(
                                        'Profili Düzenle',
                                        style: TextStyle(color: textColor),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        CosmosNavigator.pushNonAnimated(
                                          context,
                                          const EditProfilePage(),
                                        );
                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.logout,
                                          color: Colors.red[300]),
                                      title: Text(
                                        'Çıkış Yap',
                                        style:
                                            TextStyle(color: Colors.red[300]),
                                      ),
                                      onTap: () async {
                                        await CosmosFirebase.logout();
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginPage(),
                                          ),
                                          (route) => false,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: cColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderColor,
                              ),
                            ),
                            child: Icon(Icons.settings,
                                color: defaultColor, size: 20),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            CosmosNavigator.pushNonAnimated(
                              context,
                              const StatisticsPage(),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: cColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderColor,
                              ),
                            ),
                            child: Icon(Icons.bar_chart,
                                color: defaultColor, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Kategoriler Başlığı
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Kategoriler",
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "İhtiyacınız olan konuda uzman dinleyiciler bulun",
                          style: GoogleFonts.poppins(
                            color: textColor.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Kategoriler Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final categories = [
                          ["İlişki Sorunları", "assets/a/break-up.png"],
                          ["Ayrılık", "assets/a/divorce.png"],
                          ["İş Sorunları", "assets/a/fired.png"],
                          ["Sinir ve Stres", "assets/a/hair.png"],
                          ["Aile İçi Sorunlar", "assets/a/man.png"],
                          ["Çevre Baskısı", "assets/a/pressure.png"],
                          ["Düşünceler", "assets/a/stress.png"],
                          ["Maddi Sorunlar", "assets/a/money.png"],
                          ["Diğer...", "assets/a/sort.png"],
                        ];
                        if (index >= categories.length) return null;
                        return _buildCategoryCard(
                          categories[index][0],
                          categories[index][1],
                        );
                      },
                    ),
                  ),
                ),

                // İlanlar Başlığı
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Aktif İlanlar",
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Size yardımcı olmak için bekleyen ilanlar",
                          style: GoogleFonts.poppins(
                            color: textColor.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // İlanlar bölümü için
                SliverToBoxAdapter(
                  child: ValueListenableBuilder(
                    valueListenable: homeIlanlar,
                    builder: (context, value, child) {
                      if (value.isEmpty) {
                        return Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.announcement_outlined,
                                color: defaultColor,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Henüz Aktif İlan Yok',
                                style: GoogleFonts.poppins(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Şu anda yayında olan bir ilan bulunmuyor.',
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
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= homeIlanlar.value.length) return null;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: homeIlanlar.value[index],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

                // Aktif Dinleyiciler Başlığı
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Aktif Dinleyiciler",
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Şu an çevrimiçi olan uzman dinleyiciler",
                          style: GoogleFonts.poppins(
                            color: textColor.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Dinleyiciler bölümü için
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<List<dynamic>>(
                    valueListenable: homeUsers,
                    builder: (context, value, child) {
                      if (value.isEmpty) {
                        return Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.headphones_outlined,
                                color: defaultColor,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aktif Dinleyici Yok',
                                style: GoogleFonts.poppins(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Şu anda çevrimiçi olan dinleyici bulunmuyor.',
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

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: value.length,
                        itemBuilder: (context, index) {
                          return value[index];
                        },
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(String title, String imagePath) {
    return GestureDetector(
      onTap: () {
        CosmosNavigator.pushNonAnimated(
          context,
          CategoryContentPage(category: title),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cColor,
              cColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: defaultColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Image.asset(
                    imagePath,
                    width: 28,
                    height: 28,
                    color: defaultColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                ValueListenableBuilder<Map<String, int>>(
                  valueListenable: Database.activeCategoryListeners,
                  builder: (context, value, child) {
                    final count = value[title] ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: defaultColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count Dinleyici',
                        style: GoogleFonts.poppins(
                          color: defaultColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      {required IconData icon,
      required String title,
      required String message}) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: defaultColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
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
}
