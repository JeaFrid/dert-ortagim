import 'package:agor/firebase_options.dart';
import 'package:agor/page/home.dart';
import 'package:agor/page/login.dart';
import 'package:agor/services/agora.dart';
import 'package:cosmos/cosmos.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr', null);
  AgoraService.initAgora();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!kIsWeb) {
    OneSignal.initialize("549e968b-e505-4ec1-a8ad-448d4b694275");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dert Ortağım',
      debugShowCheckedModeBanner: false,
      home: CosmosFirebase.isSignedIn() == true
          ? const HomePage()
          : const LoginPage(),
    );
  }
}
