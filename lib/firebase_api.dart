import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Payload: ${message.data}');
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  final _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications',
    importance: Importance.defaultImportance,
  );

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    //listenForToken();
    await _firebaseMessaging.subscribeToTopic('general');

    // init local notifications
    await initLocalNotifications(); // For foreground handling

    // Setup Background Handler
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    // Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@mipmap/ic_launcher', // Using default icon
          ),
        ),
        payload: jsonEncode(message.toMap()),
      );
    });

    // Handle initial message (Terminated state)
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      // You can navigate here if needed:
      // Navigator.of(context).pushNamed(...)
      print('App opened from terminated state: ${initialMessage.messageId}');
    }

    // Handle App Opened (Background state)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('App opened from background state: ${message.messageId}');
      // Navigator.of(context).pushNamed(...)
    });
  }

  Future<void> initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(); // Use this for iOS
    const settings = InitializationSettings(android: android, iOS: ios);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (payload) {
        // Handle local notification tap
        final message = RemoteMessage.fromMap(jsonDecode(payload.payload!));
        print('Local Notification Tapped: ${message.messageId}');
      },
    );

    final platform = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await platform?.createNotificationChannel(_androidChannel);
  }

//   void listenForToken() {
//   // This will fire when the token is initially generated and on refresh
//   _firebaseMessaging.onTokenRefresh.listen((token) {
//     print('New APNS/FCM Token: $token');
//     // Send this token to your backend server here
//     // Example: await sendTokenToServer(token);
//   });

//   // Also try to get the current token immediately (might still be null)
//   _firebaseMessaging.getToken().then((token) {
//     if (token != null) {
//       print('Current FCM Token: $token');
//     }
//   });
// }
}
