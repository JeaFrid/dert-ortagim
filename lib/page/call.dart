import 'dart:async';
import 'package:agor/page/profile.dart';
import 'package:agor/services/agora.dart';
import 'package:agor/services/call.dart';
import 'package:agor/services/database.dart';
import 'package:agor/services/notification_services.dart';
import 'package:agor/theme/color.dart';
import 'package:cosmos/cosmos.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CallPage extends StatefulWidget {
  final String callID;
  final String tag;
  const CallPage({super.key, required this.callID, required this.tag});
  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  ValueNotifier<String> tagS = ValueNotifier("");
  ValueNotifier<String> callerIDS = ValueNotifier("");
  ValueNotifier<String> calleeS = ValueNotifier("");
  ValueNotifier<String> statusS = ValueNotifier("Aranıyor...");
  ValueNotifier<String> roomIDS = ValueNotifier("");
  ValueNotifier<String> timeS = ValueNotifier("");
  ValueNotifier<bool> loading = ValueNotifier(true);
  ValueNotifier<String> listenerName = ValueNotifier("");
  ValueNotifier<String> listenerPhoto = ValueNotifier("");
  ValueNotifier<String> listenerBio = ValueNotifier("");
  ValueNotifier<List<String>> listenerTags = ValueNotifier([]);

  Future<void> getCall() async {
    List ele = await CosmosFirebase.get('call/"${widget.tag}"', true);

    if (ele[3] == "0") {
      statusS.value = "Aranıyor...";
    } else if (ele[3] == "1") {
      statusS.value = "Çalıyor...";
    } else if (ele[3] == "2") {
      statusS.value = "Reddedildi.";
    } else if (ele[3] == "3") {
      statusS.value = "Görüşme sürüyor...";
    } else if (ele[3] == "4") {
      statusS.value = "Görüşme bitti.";
      AgoraService.leaveCall();
      Navigator.pop(context);
    }

    statusS.notifyListeners();
  }

  Future<void> _loadListenerInfo() async {
    if (calleeS.value.isNotEmpty) {
      List userData =
          await CosmosFirebase.get('users/"${calleeS.value}"', true);
      if (userData.isNotEmpty) {
        listenerName.value = userData[0];
        listenerPhoto.value = userData[3];
        listenerBio.value = userData[4];

        // Dinleyicinin etiketlerini al
        List? tags = await CosmosFirebase.get('tags/"${calleeS.value}"', true);
        if (tags != null && tags.isNotEmpty) {
          listenerTags.value = List<String>.from(tags.sublist(1));
        }
      }
    }
  }

  Timer? _timer;
  int _seconds = 0;

  String get formattedTime {
    int minutes = _seconds ~/ 60;
    int seconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void startTimer() {
    _timer =
        Timer.periodic(const Duration(seconds: 1, milliseconds: 500), (timer) {
      if (_seconds >= 3600) {
        timer.cancel(); // 1 saat dolunca durdur
      } else {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
  }

  void resetTimer() {
    stopTimer();
    setState(() {
      _seconds = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(
      const Duration(milliseconds: 1),
      () async {
        Map a = await CallClass.getCallInfo(widget.tag);
        tagS.value = a["tag"];
        callerIDS.value = a["caller_id"];
        calleeS.value = a["callee_id"];
        roomIDS.value = a["room_id"];
        timeS.value = a["time"];

        tagS.notifyListeners();
        callerIDS.notifyListeners();
        calleeS.notifyListeners();
        roomIDS.notifyListeners();
        timeS.notifyListeners();

        await _loadListenerInfo();
        await AgoraService.joinCall(widget.callID);
        await getCall();
        startTimer();
        Timer.periodic(
          const Duration(seconds: 5),
          (timer) async {
            await getCall();
          },
        );
        loading.value = false;
        loading.notifyListeners();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        tagS,
        callerIDS,
        calleeS,
        statusS,
        roomIDS,
        timeS,
        loading,
        listenerName,
        listenerPhoto,
        listenerBio,
        listenerTags,
      ]),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: loading.value == false
                ? Column(
                    children: [
                      // Üst Bilgi Alanı
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: cColor,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Dert Ortağım",
                                  style: GoogleFonts.poppins(
                                    color: defaultColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              statusS.value,
                              style: GoogleFonts.poppins(
                                color: textColor.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            if (statusS.value == "Görüşme sürüyor...")
                              Text(
                                formattedTime,
                                style: GoogleFonts.poppins(
                                  color: defaultColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Dinleyici Bilgileri
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              // Profil Fotoğrafı
                              GestureDetector(
                                onTap: () {
                                  CosmosNavigator.pushNonAnimated(
                                    context,
                                    Profile(uid: calleeS.value),
                                  );
                                },
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: defaultColor,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                defaultColor.withOpacity(0.3),
                                            blurRadius: 15,
                                            spreadRadius: 3,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.network(
                                          listenerPhoto.value,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Image.asset(
                                            "assets/user.png",
                                            width: 120,
                                            height: 120,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: statusS.value ==
                                                  "Görüşme sürüyor..."
                                              ? Colors.green
                                              : Colors.orange,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: bg,
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          statusS.value == "Görüşme sürüyor..."
                                              ? Icons.call
                                              : Icons.access_time,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // İsim
                              Text(
                                listenerName.value,
                                style: GoogleFonts.poppins(
                                  color: textColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Dinleyici Etiketi
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
                                  "Uzman Dinleyici",
                                  style: GoogleFonts.poppins(
                                    color: defaultColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Biyografi
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
                                      'Hakkında',
                                      style: GoogleFonts.poppins(
                                        color: defaultColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      listenerBio.value,
                                      style: GoogleFonts.poppins(
                                        color: textColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Uzmanlık Alanları
                              if (listenerTags.value.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Uzmanlık Alanları',
                                        style: GoogleFonts.poppins(
                                          color: defaultColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: listenerTags.value.map((tag) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  defaultColor.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: defaultColor
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Text(
                                              tag,
                                              style: GoogleFonts.poppins(
                                                color: defaultColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 24),

                              // İpuçları
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: defaultColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: defaultColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.lightbulb_outline,
                                          color: defaultColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'İpuçları',
                                          style: GoogleFonts.poppins(
                                            color: defaultColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTipItem(
                                      'Görüşme sırasında sakin ve açık olun',
                                      'Dinleyiciniz size yardımcı olmak için burada',
                                    ),
                                    _buildTipItem(
                                      'Kendinizi rahat hissedin',
                                      'Tüm görüşmeler gizli ve güvenlidir',
                                    ),
                                    _buildTipItem(
                                      'Görüşme sonrası değerlendirme yapın',
                                      'Dinleyicinize puan ve yorum bırakabilirsiniz',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Alt Kontrol Butonları
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: cColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor,
                              blurRadius: 10,
                              offset: const Offset(0, -4),
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                await CallClass.updateCall(
                                    context, widget.tag, 4);
                                await AgoraService.leaveCall();

                                // Arama süresini kaydet
                                if (calleeS.value.isNotEmpty && _seconds > 0) {
                                  await Database.saveCallDuration(
                                      calleeS.value, _seconds);

                                  // Görüşme sonlandığında bildirim gönder
                                  await NotificationServices.sendNotification(
                                    userId: calleeS.value,
                                    title: "Görüşme Sonlandı",
                                    message:
                                        "${Database.profileName.value} ile ${_seconds} saniyelik görüşmeniz sonlandı.",
                                    type: "call",
                                  );
                                }

                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red[800],
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.call_end,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: CupertinoActivityIndicator(
                      color: Colors.white,
                      radius: 12,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildTipItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: defaultColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: textColor.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
