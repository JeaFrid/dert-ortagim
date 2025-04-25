import 'package:cosmos/cosmos.dart';
import 'package:flutter/material.dart';

class NotificationServices extends ChangeNotifier {
  // Kullanıcının bildirimlerini getir
  static Future<List> getNotifications() async {
    try {
      String uid = await CosmosFirebase.getUID();
      List notifications = await CosmosFirebase.getOnce("notifications/$uid");
      return notifications;
    } catch (e) {
      print("Bildirimler alınırken hata: $e");
      return [];
    }
  }

  // Bildirim gönder
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      String notificationId = DateTime.now().millisecondsSinceEpoch.toString();
      String time = CosmosTime.getNowTimeString();

      await CosmosFirebase.add(
        reference: "notifications/$userId",
        tag: notificationId,
        value: [
          notificationId,
          title,
          message,
          time,
          "0", // 0: Okunmadı, 1: Okundu
          type, // call, review, wallet, warning, vb.
        ],
      );
    } catch (e) {
      print("Bildirim gönderilirken hata: $e");
    }
  }

  // Bildirimi okundu olarak işaretle
  static Future<void> markAsRead(String notificationId) async {
    try {
      String uid = await CosmosFirebase.getUID();
      List notification = await CosmosFirebase.get(
          'notifications/$uid/"$notificationId"', true);

      if (notification.isNotEmpty) {
        notification[4] = "1"; // Okundu olarak işaretle

        await CosmosFirebase.add(
          reference: "notifications/$uid",
          tag: notificationId,
          value: notification,
        );
      }
    } catch (e) {
      print("Bildirim okundu olarak işaretlenirken hata: $e");
    }
  }

  // Bildirimi sil
  static Future<void> deleteNotification(String notificationId) async {
    try {
      String uid = await CosmosFirebase.getUID();
      await CosmosFirebase.delete('notifications/$uid/"$notificationId"');
    } catch (e) {
      print("Bildirim silinirken hata: $e");
    }
  }

  // Tüm bildirimleri temizle
  static Future<void> clearAllNotifications() async {
    try {
      String uid = await CosmosFirebase.getUID();
      List notifications = await CosmosFirebase.getOnce("notifications/$uid");

      for (var notification in notifications) {
        if (notification is List && notification.isNotEmpty) {
          await CosmosFirebase.delete(
              'notifications/$uid/"${notification[0]}"');
        }
      }
    } catch (e) {
      print("Tüm bildirimler temizlenirken hata: $e");
    }
  }

  // Arama bildirimi gönder
  static Future<void> sendCallNotification({
    required String userId,
    required String callerName,
  }) async {
    await sendNotification(
      userId: userId,
      title: "Yeni Arama",
      message: "$callerName sizi aradı",
      type: "call",
    );
  }

  // Değerlendirme bildirimi gönder
  static Future<void> sendReviewNotification({
    required String userId,
    required String reviewerName,
    required int rating,
  }) async {
    await sendNotification(
      userId: userId,
      title: "Yeni Değerlendirme",
      message: "$reviewerName size $rating yıldız verdi",
      type: "review",
    );
  }

  // Cüzdan bildirimi gönder
  static Future<void> sendWalletNotification({
    required String userId,
    required String amount,
    required String operation,
  }) async {
    String message = operation == "add"
        ? "Hesabınıza $amount TL eklendi"
        : "Hesabınızdan $amount TL çekildi";

    await sendNotification(
      userId: userId,
      title: "Cüzdan İşlemi",
      message: message,
      type: "wallet",
    );
  }

  // Uyarı bildirimi gönder
  static Future<void> sendWarningNotification({
    required String userId,
    required String warningMessage,
  }) async {
    await sendNotification(
      userId: userId,
      title: "Önemli Uyarı",
      message: warningMessage,
      type: "warning",
    );
  }
}
