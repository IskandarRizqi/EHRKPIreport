import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ehr_report/cuti.dart';
import 'package:ehr_report/halamanutama.dart';
import 'package:ehr_report/pagelogin.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:ehr_report/firebase_option.dart';
import 'dart:io';
import 'dart:developer';
import 'package:flutter/services.dart';



Future <void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
   print("Initializing Firebase...");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Firebase Initialized");

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  easyLoadingCustomization();

  HttpOverrides.global = MyHttpOverrides();

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    print("FlutterError caught: ${errorDetails.toString()}");
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    print("PlatformError caught: $error");
    return true;
  };

  initializeFirebaseMessaging();
  runApp(const MyApp());
}
void initializeFirebaseMessaging() async {
  final fcmToken = await FirebaseMessaging.instance.getToken();
  // final fcmToken = null;
  print("FCM Token: $fcmToken");

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });
}
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
void easyLoadingCustomization() {
  EasyLoading.instance
    ..indicatorType = EasyLoadingIndicatorType.ring
    ..loadingStyle = EasyLoadingStyle.dark;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
  print("Building EhrApp...");
  return GetMaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'EHR SYSTEM',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: const LoginPage(),
    builder: (context, child) {
      print("Initializing EasyLoading...");
      // Pastikan EasyLoading.init() diterapkan dengan benar
      return EasyLoading.init()(context, child);
    },
    routes: {
      '/cutireport': (context) => const EmployeeLeavePage(prevPage: 'home'),
      // '/pendidikan': (context) => const PendidikanWidget(prevPage: 'home'),
      // '/kalenderkerja': (context) =>
      //     const KalendarReportPage(prevPage: 'home'),
      // '/gaji': (context) => const PayRollWidget(prevPage: 'home'),
      // '/perizinan': (context) => const TerPlgWidget(),
      // '/lembur': (context) => const LemburWidget(prevPage: 'home'),
      // '/cuti': (context) => const PerizinanWidget(prevPage: 'home'),
      // '/elearning': (context) => const ElearningWidget(),
      // '/elibrary': (context) => const Elibrary(prevPage: 'home'),
      // '/kunjungan': (context) => const KunjunganWidget(prevPage: 'home'),
      // '/todokpi': (context) => const TodoWidget(prevPage: 'home'),
      // '/audit': (context) => const AuditWidget(prevPage: 'home'),
      // '/auditrealisasi': (context) =>
      //     const RealisasiAuditWidget(prevPage: 'home'),
      // '/berita': (context) => const News(prevPage: 'home'),
      // '/kpi': (context) => const DashboardKpiWidget(prevPage: 'home'),
    },
  );
}

}