import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  static Future<void> printFCMToken() async {
    // طلب صلاحية الإشعارات
    await FirebaseMessaging.instance.requestPermission();

    // الحصول على التوكن
    String? token = await FirebaseMessaging.instance.getToken();

    print("======================================");
    print("FCM TOKEN:");
    print(token);
    print("======================================");

    // في حال تغير التوكن
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print("NEW FCM TOKEN:");
      print(newToken);
    });
  }
}