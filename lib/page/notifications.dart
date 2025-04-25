import 'package:agor/services/notification_services.dart';
import 'package:agor/theme/color.dart';
import 'package:cosmos/cosmos.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  ValueNotifier<List<Map<String, dynamic>>> notifications = ValueNotifier([]);
  ValueNotifier<bool> isLoading = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      isLoading.value = true;
      List notificationList = await NotificationServices.getNotifications();
      notifications.value = notificationList.map((notification) {
        return {
          'id': notification[0],
          'title': notification[1],
          'message': notification[2],
          'time': notification[3],
          'isRead': notification[4] == "1",
          'type': notification[5],
        };
      }).toList();
      isLoading.value = false;
    } catch (e) {
      print("Bildirimler yüklenirken hata: $e");
      notifications.value = [];
      isLoading.value = false;
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    await NotificationServices.markAsRead(notificationId);
    await _loadNotifications();
  }

  Future<void> _deleteNotification(String notificationId) async {
    await NotificationServices.deleteNotification(notificationId);
    await _loadNotifications();
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
          'Bildirimler',
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep, color: defaultColor),
            onPressed: () async {
              await NotificationServices.clearAllNotifications();
              await _loadNotifications();
            },
            tooltip: 'Tüm bildirimleri temizle',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([notifications, isLoading]),
        builder: (context, child) {
          if (isLoading.value) {
            return Center(
              child: CircularProgressIndicator(
                color: defaultColor,
              ),
            );
          }

          if (notifications.value.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: textColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bildiriminiz Yok',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yeni bildirimler geldiğinde burada görünecek',
                    style: GoogleFonts.poppins(
                      color: textColor.withOpacity(0.6),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.value.length,
            itemBuilder: (context, index) {
              final notification = notifications.value[index];
              return _buildNotificationCard(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    IconData iconData;
    Color iconColor;

    // Bildirim tipine göre ikon ve renk belirle
    switch (notification['type']) {
      case 'call':
        iconData = Icons.call;
        iconColor = Colors.green;
        break;
      case 'review':
        iconData = Icons.star;
        iconColor = Colors.amber;
        break;
      case 'wallet':
        iconData = Icons.account_balance_wallet;
        iconColor = Colors.blue;
        break;
      case 'warning':
        iconData = Icons.warning;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = defaultColor;
    }

    return Dismissible(
      key: Key(notification['id']),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteNotification(notification['id']);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notification['isRead'] ? cColor : cColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification['isRead']
                ? borderColor
                : defaultColor.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (!notification['isRead']) {
                _markAsRead(notification['id']);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notification['title'],
                                style: GoogleFonts.poppins(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: notification['isRead']
                                      ? FontWeight.w500
                                      : FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!notification['isRead'])
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: defaultColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification['message'],
                          style: GoogleFonts.poppins(
                            color: textColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CosmosTime.getDateTR(
                            CosmosTime.getDateTime(notification['time']),
                          ),
                          style: GoogleFonts.poppins(
                            color: textColor.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
