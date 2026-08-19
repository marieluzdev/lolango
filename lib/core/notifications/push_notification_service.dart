import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lolango_v2/core/supabase/supabase_client.dart';
import 'package:lolango_v2/firebase_options.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return PushNotificationService(ref.watch(supabaseProvider));
});

const _androidNotificationChannelId = 'lolango_notifications';
const _androidNotificationChannelName = 'Notifications Lolango';
const _androidNotificationChannelDescription =
    'Canal de notifications pour Lolango';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM] Background message received: ${message.messageId}');
}

class PushNotificationService {
  final SupabaseClient _supabase;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  PushNotificationService(this._supabase);

  Future<void> initialize() async {
    if (_initialized) return;

    final settings = await _messaging.getNotificationSettings();
    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    const androidInitializationSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iOSInitializationSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iOSInitializationSettings,
    );
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[FCM] Notification clicked: ${response.payload}');
      },
    );

    const androidChannel = AndroidNotificationChannel(
      _androidNotificationChannelId,
      _androidNotificationChannelName,
      description: _androidNotificationChannelDescription,
      importance: Importance.max,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    FirebaseMessaging.onMessage.listen((message) async {
      debugPrint('[FCM] Foreground message received: ${message.messageId}');
      debugPrint('[FCM] Message data: ${message.data}');
      debugPrint('[FCM] Message notification: ${message.notification}');
      await _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] Notification opened: ${message.messageId}');
    });

    _messaging.onTokenRefresh.listen((token) {
      debugPrint('[FCM] Token refreshed: $token');
      _saveTokenToSupabase(token);
    });

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToSupabase(token);
    }

    _initialized = true;
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    debugPrint(
      '[FCM] Showing local notification for message: ${message.messageId}',
    );
    if (notification == null) {
      debugPrint('[FCM] No notification payload to show.');
      return;
    }

    final title = notification.title ?? 'Lolango';
    final body = notification.body ?? '';
    final payload = message.data.isNotEmpty ? message.data.toString() : null;

    const androidDetails = AndroidNotificationDetails(
      _androidNotificationChannelId,
      _androidNotificationChannelName,
      channelDescription: _androidNotificationChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      playSound: true,
      ticker: 'ticker',
    );
    const iosDetails = DarwinNotificationDetails();
    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: payload,
    );
  }

  Future<String?> refreshToken() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
      '[FCM] Permission status on refresh: ${settings.authorizationStatus}',
    );

    final token = await _messaging.getToken();
    debugPrint('[FCM] Retrieved refreshed token: $token');
    if (token != null) {
      final saved = await _saveTokenToSupabase(token);
      debugPrint('[FCM] Token save result: $saved');
    }

    return token;
  }

  Future<bool> requestNotificationPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
        
    if (granted) {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToSupabase(token);
      }
    }
    
    return granted;
  }

  Future<bool> _saveTokenToSupabase(String token) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('[FCM] Aucun utilisateur connecté, token non enregistré.');
      return false;
    }
    debugPrint(
      '[FCM] Saving token to Supabase, userId=${user.id}, token=$token',
    );

    try {
      final profileCheck = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (profileCheck == null) {
        debugPrint(
          '[FCM] Aucun profil existant pour user ${user.id}. Impossible de stocker fcm_token dans public.profiles.',
        );
        return false;
      }

      final response = await _supabase
          .from('profiles')
          .update({
            'fcm_token': token,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', user.id);

      debugPrint('[FCM] Réponse update FCM token: $response');
      if (response is Map<String, dynamic> && response['error'] != null) {
        debugPrint(
          '[FCM] Erreur lors de l\'enregistrement du token FCM : ${response['error']}',
        );
        return false;
      }

      debugPrint('[FCM] Token enregistré pour user ${user.id}.');
      return true;
    } catch (error) {
      debugPrint(
        '[FCM] Erreur lors de l\'enregistrement du token FCM : $error',
      );
      return false;
    }
  }
}
