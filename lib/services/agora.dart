import 'package:agor/constant/key.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'database.dart';

class AgoraService {
  static late final RtcEngine engine;
  static void setupEventHandlers() {
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onAudioVolumeIndication:
            (connection, speakers, speakerNumber, totalVolume) {
          if (speakers.isNotEmpty) {
            print("🔊 Ses Seviyesi: ${speakers.first.volume}");
          }
        },
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print("✅ Agora'ya başarıyla bağlandı: ${connection.channelId}");
          engine.setEnableSpeakerphone(true); // Agora bağlandıysa hoparlörü aç
        },
        onConnectionStateChanged: (RtcConnection connection,
            ConnectionStateType state, ConnectionChangedReasonType reason) {
          print("🔄 Agora bağlantı durumu değişti: $state (Sebep: $reason)");
          if (state == ConnectionStateType.connectionStateConnected) {
            engine.setEnableSpeakerphone(
                true); // Bağlantı kurulduğunda hoparlörü aç
          }
        },
        onError: (ErrorCodeType err, String msg) {
          print("🚨 Agora Hatası: $err - $msg");
        },
      ),
    );
  }

  static Future<void> initAgora() async {
    engine = createAgoraRtcEngine();
    await engine.initialize(const RtcEngineContext(
      appId: appId,
    ));
    await engine.enableAudioVolumeIndication(
        interval: 200, smooth: 3, reportVad: false);

    await engine.enableAudio();
    setupEventHandlers();
    await engine
        .setChannelProfile(ChannelProfileType.channelProfileCommunication);
    await engine.enableLocalAudio(true);
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileMusicStandard,
      scenario: AudioScenarioType.audioScenarioGameStreaming,
    );
  }

  static Future<void> joinCall(String channelId) async {
    var status = await Permission.microphone.request();

    if (status.isDenied) {
      print(
          "⚠ Mikrofon izni reddedildi. Çağrı başlatılıyor ama ses çalışmayabilir!");
    } else if (status.isPermanentlyDenied) {
      print(
          "🚨 Mikrofon izni kalıcı olarak reddedildi! Ayarlardan elle açmalısın.");
      openAppSettings();
    }

    await engine.enableLocalAudio(true);

    await engine.joinChannel(
      token: "",
      channelId: channelId,
      uid: int.parse(Database.profileID.value),
      options: const ChannelMediaOptions(),
    );
    await Future.delayed(const Duration(seconds: 2));

    if (await engine.getConnectionState() ==
        ConnectionStateType.connectionStateConnected) {
      await engine.setEnableSpeakerphone(true);
    } else {
      print("⚠ Agora bağlantısı kurulamadı, hoparlör değiştirilemiyor!");
    }
    await engine.setDefaultAudioRouteToSpeakerphone(true);

    await engine.enableLoopbackRecording(enabled: false);

    print("✅ Çağrıya katıldın.");
  }

  static Future<void> leaveCall() async {
    await engine.leaveChannel();
  }

  static Future<void> dispose() async {
    await engine.release();
  }
}
