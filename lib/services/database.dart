import 'package:agor/controller/controller.dart';
import 'package:agor/page/home.dart';
import 'package:agor/services/online.dart';
import 'package:agor/widget/person.dart';
import 'package:cosmos/cosmos.dart';
import 'package:flutter/material.dart';

import '../widget/ilan.dart';

class Database extends ChangeNotifier {
  static ValueNotifier<String> profileName = ValueNotifier("");
  static ValueNotifier<String> profileEmail = ValueNotifier("");
  static ValueNotifier<String> profilePassword = ValueNotifier("");
  static ValueNotifier<String> profilePhoto = ValueNotifier("");
  static ValueNotifier<String> profileBio = ValueNotifier("");
  static ValueNotifier<String> profileTime = ValueNotifier("");
  static ValueNotifier<String> profileID = ValueNotifier("");
  static ValueNotifier<String> profileUID = ValueNotifier("");
  static ValueNotifier<String> profileGender = ValueNotifier("");
  static ValueNotifier<String> profileUserType = ValueNotifier("");
  static ValueNotifier<String> profileWallet = ValueNotifier("0");
  static ValueNotifier<int> totalCallDuration = ValueNotifier(0);
  static ValueNotifier<int> totalCalls = ValueNotifier(0);

  static ValueNotifier<String> profileNameYou = ValueNotifier("");
  static ValueNotifier<String> profileEmailYou = ValueNotifier("");
  static ValueNotifier<String> profilePasswordYou = ValueNotifier("");
  static ValueNotifier<String> profilePhotoYou = ValueNotifier("");
  static ValueNotifier<String> profileBioYou = ValueNotifier("");
  static ValueNotifier<String> profileTimeYou = ValueNotifier("");
  static ValueNotifier<String> profileIDYou = ValueNotifier("");
  static ValueNotifier<String> profileUIDYou = ValueNotifier("");
  static ValueNotifier<String> profileGenderYou = ValueNotifier("");
  static ValueNotifier<String> profileUserTypeYou = ValueNotifier("");

  static Future<void> getMyProfile({String? id}) async {
    try {
      if (id == null) {
        String axc = await CosmosFirebase.getUID();
        profileUID.value = axc;
        List x = await CosmosFirebase.get('users/"$axc"', true);
        profileName.value = x[0];
        profileEmail.value = x[1];
        profilePassword.value = x[2];
        profilePhoto.value = x[3];
        profileBio.value = x[4];
        profileTime.value = x[5];
        profileID.value = x[6];
        profileGender.value = x[7];
        profileUserType.value = x[8];

        // Cüzdan bakiyesini al
        if (x.length > 10) {
          profileWallet.value = x[10];
        } else {
          profileWallet.value = "0";
        }

        // Arama istatistiklerini yükle
        await loadCallStatistics();
      } else {
        profileUIDYou.value = id;
        List x = await CosmosFirebase.get('users/"$id"', true);
        profileNameYou.value = x[0];
        profileEmailYou.value = x[1];
        profilePasswordYou.value = x[2];
        profilePhotoYou.value = x[3];
        profileBioYou.value = x[4];
        profileTimeYou.value = x[5];
        profileIDYou.value = x[6];
        profileGenderYou.value = x[7];
        profileUserTypeYou.value = x[8];
      }
    } catch (e) {
      print(e);
    }
  }

  // Arama istatistiklerini yükle
  static Future<void> loadCallStatistics() async {
    try {
      String uid = profileUID.value;
      if (uid.isEmpty) {
        uid = await CosmosFirebase.getUID();
      }

      // Arama istatistiklerini al
      List? callStats = await CosmosFirebase.get('call_stats/"$uid"', true);

      if (callStats != null && callStats.isNotEmpty) {
        totalCalls.value = int.tryParse(callStats[1].toString()) ?? 0;
        totalCallDuration.value = int.tryParse(callStats[2].toString()) ?? 0;
      } else {
        totalCalls.value = 0;
        totalCallDuration.value = 0;
      }
    } catch (e) {
      print("Arama istatistikleri yüklenirken hata: $e");
      totalCalls.value = 0;
      totalCallDuration.value = 0;
    }
  }

  // Arama süresini kaydet
  static Future<void> saveCallDuration(
      String calleeId, int durationInSeconds) async {
    try {
      String uid = await CosmosFirebase.getUID();

      // Arayanın istatistiklerini güncelle
      await _updateUserCallStats(uid, durationInSeconds);

      // Arananın istatistiklerini güncelle
      await _updateUserCallStats(calleeId, durationInSeconds);

      // Arama kaydını ekle
      String callId = DateTime.now().millisecondsSinceEpoch.toString();
      await CosmosFirebase.add(
        reference: "calls",
        tag: callId,
        value: [
          callId,
          uid,
          calleeId,
          durationInSeconds.toString(),
          CosmosTime.getNowTimeString(),
        ],
      );

      // İstatistikleri yeniden yükle
      await loadCallStatistics();
    } catch (e) {
      print("Arama süresi kaydedilirken hata: $e");
    }
  }

  // Kullanıcının arama istatistiklerini güncelle
  static Future<void> _updateUserCallStats(
      String userId, int durationInSeconds) async {
    try {
      List? existingStats =
          await CosmosFirebase.get('call_stats/"$userId"', true);

      if (existingStats != null && existingStats.isNotEmpty) {
        // Mevcut istatistikleri güncelle
        int currentCalls = int.tryParse(existingStats[1].toString()) ?? 0;
        int currentDuration = int.tryParse(existingStats[2].toString()) ?? 0;

        await CosmosFirebase.add(
          reference: "call_stats",
          tag: userId,
          value: [
            userId,
            (currentCalls + 1).toString(),
            (currentDuration + durationInSeconds).toString(),
          ],
        );
      } else {
        // Yeni istatistik oluştur
        await CosmosFirebase.add(
          reference: "call_stats",
          tag: userId,
          value: [
            userId,
            "1",
            durationInSeconds.toString(),
          ],
        );
      }
    } catch (e) {
      print("Kullanıcı arama istatistikleri güncellenirken hata: $e");
    }
  }

  static Future<void> getIlanlar() async {
    homeIlanlar.value.clear();
    List users = await CosmosFirebase.getOnce("users");
    List xxx = await CosmosFirebase.getOnce("ilan");
    for (List element in xxx) {
      List a = [];
      for (List usr in users) {
        if (element[1] == usr[usr.length - 1].replaceAll('"', "")) {
          a = usr;
        }
      }
      if (!isTimeDMT45m(element[4], CosmosTime.getNowTimeString())) {
        homeIlanlar.value.add(
          Ilan(
            text: element[2],
            bio: element[3],
            id: element[0],
            uid: element[1],
            time: CosmosTime.getDateTR(CosmosTime.getDateTime(element[4])),
            name: a[0],
          ),
        );
      }

      homeIlanlar.notifyListeners();
    }
  }

  static Future<void> getUsers() async {
    List x = [];
    homeUsers.value.clear();
    String uid = await CosmosFirebase.getUID();
    x = await CosmosFirebase.getOnce("users");
    List y = CosmosTools.sortFromList(x, 5);
    for (List element in y.reversed.toList()) {
      if (uid != element[element.length - 1].replaceAll('"', "")) {
        homeUsers.value.add(
          Person(
            image: element[3],
            text: element[0],
            bio: element[4],
            uid: element[element.length - 1].replaceAll('"', ""),
          ),
        );
        homeUsers.notifyListeners();
      }
    }
  }

  static ValueNotifier<Map<String, int>> activeCategoryListeners =
      ValueNotifier({});

  static Future<void> updateActiveCategoryListeners() async {
    Map<String, int> categoryCount = {
      "İlişki Sorunları": 0,
      "Ayrılık": 0,
      "İş Sorunları": 0,
      "Sinir ve Stres": 0,
      "Aile İçi Sorunlar": 0,
      "Çevre Baskısı": 0,
      "Düşünceler": 0,
      "Maddi Sorunlar": 0,
      "Diğer": 0,
    };

    // Tüm kullanıcıları al
    List users = await CosmosFirebase.getOnce("users");

    for (List user in users) {
      // Sadece dinleyicileri ve tatil modunda olmayanları kontrol et
      if (user.length > 9 && user[8] == "Dinleyici" && user[9] == "0") {
        String uid = user[user.length - 1].replaceAll('"', "");

        // Kullanıcının etiketlerini al
        List? tags = await CosmosFirebase.get('tags/"$uid"', true);
        if (tags != null && tags.isNotEmpty) {
          // İlk eleman tag ID'si olduğu için onu atlıyoruz
          List<String> userTags = List<String>.from(tags.sublist(1));

          // Her bir kategori için sayacı artır
          for (String tag in userTags) {
            if (categoryCount.containsKey(tag)) {
              categoryCount[tag] = (categoryCount[tag] ?? 0) + 1;
            }
          }
        }
      }
    }

    activeCategoryListeners.value = categoryCount;
    activeCategoryListeners.notifyListeners();
  }

  static Future<List<Person>> getCategoryListeners(String category) async {
    List<Person> listeners = [];
    List users = await CosmosFirebase.getOnce("users");

    for (List user in users) {
      // Sadece dinleyicileri ve tatil modunda olmayanları kontrol et
      if (user.length > 9 && user[8] == "Dinleyici" && user[9] == "0") {
        String uid = user[user.length - 1].replaceAll('"', "");

        // Kullanıcının etiketlerini al
        List? tags = await CosmosFirebase.get('tags/"$uid"', true);
        if (tags != null && tags.isNotEmpty) {
          List<String> userTags = List<String>.from(tags.sublist(1));

          // Kullanıcı bu kategoride etiketlenmiş mi kontrol et
          if (userTags.contains(category)) {
            listeners.add(
              Person(
                image: user[3],
                text: user[0],
                bio: user[4],
                uid: uid,
              ),
            );
          }
        }
      }
    }

    return listeners;
  }
}
