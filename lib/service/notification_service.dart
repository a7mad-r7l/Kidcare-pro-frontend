import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/helper/secure_storage_service.dart';
import '../controllers/home/home_controller.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log("📩 إشعار جديد في الخلفية للطبيب (Background/Terminated): ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _appointmentsChannel =
  AndroidNotificationChannel(
    'doctor_appointments_channel',
    'Appointments Notifications',
    description: 'This channel is used for new or cancelled appointments.',
    importance: Importance.max,
    playSound: true,
  );

  static Future<void> initialize() async {
    // 1. طلب الصلاحيات
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log("🔔 تم منح صلاحيات الإشعارات بنجاح من قبل الطبيب.");
    }

    // 2. إنشاء قناة الإشعارات للأندرويد
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
    >()
        ?.createNotificationChannel(_appointmentsChannel);

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    // 3. تهيئة Local Notifications
    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          _handleNotificationClick(response.payload!);
        }
      },
    );

    // 4. معالجة الإشعارات في الخلفية
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. استلام الإشعارات أثناء فتح التطبيق (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("📥 استلام إشعار حي وتطبيق الطبيب مفتوح: ${message.notification?.title}");
      _showLocalNotification(message);

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().hasUnreadNotifications.value = true;
      }
    });

    // 6. النقر على الإشعار والتطبيق في الخلفية
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("🖱️ تم النقر على الإشعار وتطبيق الطبيب بالخلفية");
      if (message.data.containsKey('type')) {
        _handleNotificationClick(message.data['type'].toString());
      }
    });

    // 7. النقر على الإشعار والتطبيق مغلق تماماً (Terminated)
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null && initialMessage.data.containsKey('type')) {
      log("🚀 إقلاع تطبيق الطبيب من الصفر بنقرة إشعار");
      _handleNotificationClick(initialMessage.data['type'].toString());
    }

    // 🌟 الإضافة الجديدة: الاستماع لتحديث التوكن التلقائي من Firebase
    _messaging.onTokenRefresh.listen((fcmToken) {
      log("🔄 Firebase قام بتحديث FCM Token، جاري إرساله للسيرفر...");
      sendFCMTokenToServer();
    }).onError((err) {
      log("❌ خطأ أثناء تحديث FCM Token: $err");
    });
  }

  // 8. جلب التوكن وإرساله للسيرفر
  static Future<void> sendFCMTokenToServer() async {
    try {
      String? fcmToken = await _messaging.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        log("🔑 DOCTOR FCM TOKEN = $fcmToken");

        String doctorToken = await SecureStorage.getToken();
        if (doctorToken.isEmpty || doctorToken == 'null') {
          log("⚠️ لم يتم إرسال FCM Token لأن الطبيب لم يسجل دخوله بعد.");
          return;
        }

        // 🌟 التعديل الهام: تصحيح المسار ليكون خاصاً بالطبيب وليس الأهل
        final response = await http.post(
          Uri.parse('$baseUrl/api/doctor/save-fcm-token'), // 👈 تأكد من مطور الباك إند أن هذا هو المسار الصحيح
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $doctorToken',
          },
          body: {'fcm_token': fcmToken},
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          log("✅ تم حفظ الـ FCM Token للطبيب في الباك إند بنجاح!");
        } else {
          log("⚠️ الباك إند رفض التوكن (السبب: ${response.statusCode}) - ${response.body}");
        }
      }
    } catch (e) {
      log("❌ فشل توليد أو إرسال الـ FCM Token للطبيب: $e");
    }
  }

  static void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      String notificationType = message.data['type']?.toString() ?? 'general';

      _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _appointmentsChannel.id,
            _appointmentsChannel.name,
            channelDescription: _appointmentsChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            // 👈 التعديل هنا: إجبار استخدام أيقونة التطبيق الافتراضية لتجنب الانهيار الصامت
            icon: '@mipmap/ic_launcher',
            playSound: true,
          ),
        ),
        payload: notificationType,
      );
    }
  }

  static void _handleNotificationClick(String type) {
    log("🔀 جاري توجيه الطبيب بناءً على نوع الإشعار: $type");
    final typeLower = type.toLowerCase();

    Get.offAllNamed('/doctor_home');

    Future.delayed(const Duration(milliseconds: 500), () {
      if (Get.isRegistered<HomeController>()) {
        final homeCtrl = Get.find<HomeController>();
        homeCtrl.fetchAllDashboardData();

        if (typeLower.contains('cancel') || typeLower.contains('appointment')) {
          homeCtrl.currentIndex.value = 1;
        } else if (typeLower.contains('arrived')) {
          homeCtrl.currentIndex.value = 0;
        }
      }
    });
  }
}