import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initializeNotifications();
    requestNotificationPermission(); // POST_NOTIFICATIONS
    requestExactAlarmPermission();   // SCHEDULE_EXACT_ALARM
  }

  Future<void> _initializeNotifications() async {
    // Configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Icono para la notificación

    // Configuración para iOS (opcional, si también quieres iOS)
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Manejar el clic en la notificación
        final String? payload = notificationResponse.payload;
        if (payload != null) {
          debugPrint('notification payload: $payload');
        }
        // Puedes navegar a una pantalla específica, etc.
      },
    );
  }

  

  Future<void> _showNotification() async {
    // Detalles de la notificación para Android
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'your channel id', // ID del canal de notificación (único para tu app)
      'your channel name', // Nombre del canal (visible para el usuario)
      channelDescription: 'your channel description', // Descripción del canal
      importance: Importance.max, // Nivel de importancia
      priority: Priority.high, // Nivel de prioridad
      ticker: 'ticker text', // Texto que aparece brevemente en la barra de estado
      icon: '@mipmap/ic_launcher', // Icono pequeño de la notificación
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'), // Icono grande
      styleInformation: BigTextStyleInformation('Tu mensaje de notificación detallado aquí. Puede ser un texto más largo.'),
      // Puedes añadir sonido, vibración, luces, etc.
      // sound: RawResourceAndroidNotificationSound('tu_sonido'), // Si tienes un sonido personalizado
      // enableVibration: true,
      // vibratePattern: Int64List.fromList([0, 1000, 500, 2000]),
    );

    // Detalles generales de la notificación
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      // iOS: DarwinNotificationDetails(), // Si también quieres personalizar para iOS
    );

    await flutterLocalNotificationsPlugin.show(
      0, // ID de la notificación (debe ser único para cada notificación)
      'Título de la Notificación',
      'Este es el cuerpo de tu notificación.',
      notificationDetails,
      payload: 'item x', // Datos que puedes pasar al hacer clic
    );
  }

  
Future<void> requestNotificationPermission() async {
  if (Platform.isAndroid) {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }
}

Future<void> requestExactAlarmPermission() async {
  if (Platform.isAndroid) {
    final info = await DeviceInfoPlugin().androidInfo;
    final sdk = info.version.sdkInt;

    if (sdk >= 31) {
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      );
      await intent.launch();
    }
  }
}


  Future<void> _showScheduledNotification() async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Notificación Programada',
      'Esta notificación aparecerá en 5 segundos.',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled channel id',
          'Scheduled Channel Name',
          channelDescription: 'Canal para notificaciones programadas',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Para notificaciones exactas incluso en modo Doze
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'scheduled_item',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Notificaciones Locales'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _showNotification,
                child: const Text('Mostrar Notificación Ahora'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _showScheduledNotification,
                child: const Text('Programar Notificación (5s)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
}