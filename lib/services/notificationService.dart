import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// Initialise le service de notification (à appeler dans le main)
  static Future<void> initialize() async {
    // ANDROID — on conserve tel quel
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS — on AJOUTE ceci (nécessaire pour éviter le crash)
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // Demander la permission si nécessaire (Android 13+) — on garde
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // (Optionnel) Sur iOS, la demande est déjà gérée par iosSettings.*
    // Si tu préfères forcer via permission_handler côté iOS :
    // if (Platform.isIOS && await Permission.notification.isDenied) {
    //   await Permission.notification.request();
    // }
  }

  /// Affiche une notification simple
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Android — inchangé
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel_id',
      'Notifications',
      channelDescription: 'Canal de notifications locales',
      importance: Importance.max,
      priority: Priority.high,
    );

    // iOS — on AJOUTE un fallback simple (silencieux si non créé)
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }
}
