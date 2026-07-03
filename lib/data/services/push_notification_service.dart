import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:sehatiku_mobile/data/models/auth_models.dart';
import 'package:sehatiku_mobile/data/services/api_client.dart';
import 'package:sehatiku_mobile/data/repositories/auth_store.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const _androidChannel = AndroidNotificationChannel(
    'sehatiku_push',
    'Sehatiku Notifications',
    description: 'System notifications from Sehatiku',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  late final FirebaseMessaging _messaging;

  bool _initialized = false;
  bool _refreshAfterInit = false;
  String? _registeredToken;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  StreamSubscription<RemoteMessage>? _messageOpenedSub;
  ValueChanged<Map<String, dynamic>>? _onTap;

  Future<void> initialize({ValueChanged<Map<String, dynamic>>? onTap}) async {
    _onTap = onTap;
    debugPrint('[Push] initialize() called. Current _initialized=$_initialized');
    if (_initialized) {
      await _refreshRegistrationFromSession();
      return;
    }

    try {
      debugPrint('[Push] Initializing Firebase...');
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _messaging = FirebaseMessaging.instance;
      
      debugPrint('[Push] Configuring local notifications...');
      await _configureLocalNotifications();
      
      debugPrint('[Push] Requesting push permission...');
      await _requestPermission();
      
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      _messageSub = FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      _messageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
        debugPrint('[Push] onTokenRefresh triggered with token: ${_maskToken(token)}');
        await _registerToken(token);
      });

      debugPrint('[Push] Fetching initial message...');
      _messaging.getInitialMessage().then((initialMessage) {
        debugPrint('[Push] getInitialMessage finished. Message: ${initialMessage != null ? 'non-null' : 'null'}');
        if (initialMessage != null) {
          _handleTap(initialMessage);
        }
      }).catchError((e) {
        debugPrint('[Push] Failed to get initial message: $e');
      });

      _initialized = true;
      debugPrint('[Push] PushNotificationService initialized successfully');
      
      if (_refreshAfterInit) {
        debugPrint('[Push] _refreshAfterInit is true, triggering sync...');
        _refreshAfterInit = false;
        await _refreshRegistrationFromSession();
      } else {
        await _refreshRegistrationFromSession();
      }
    } catch (e, stackTrace) {
      debugPrint('[Push] Failed to initialize PushNotificationService: $e');
      debugPrint('$stackTrace');
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _messageSub?.cancel();
    await _messageOpenedSub?.cancel();
  }

  Future<void> syncPatientSession() async {
    debugPrint('[Push] syncPatientSession() called. session=${AuthStore.instance.session?.actorType}, _initialized=$_initialized');
    if (AuthStore.instance.session?.actorType != ActorType.patient) {
      await clearDeviceToken();
      return;
    }
    if (!_initialized) {
      debugPrint('[Push] Service not initialized yet during sync, setting _refreshAfterInit = true');
      _refreshAfterInit = true;
      return;
    }
    await _refreshRegistrationFromSession();
  }

  Future<void> clearDeviceToken() async {
    final token = _registeredToken;
    _registeredToken = null;
    debugPrint('[Push] clearDeviceToken() called. Current token=${token != null ? _maskToken(token) : 'null'}');
    if (token == null) return;

    try {
      if (kDebugMode) {
        debugPrint(
          '[Push] DELETE /api/v1/patients/device-tokens token=${_maskToken(token)}',
        );
      }
      await ApiClient.instance.delete(
        '/api/v1/patients/device-tokens',
        data: {'token': token},
      );
      if (kDebugMode) {
        debugPrint('[Push] DELETE /api/v1/patients/device-tokens success');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Push] DELETE /api/v1/patients/device-tokens failed: $e');
      }
      // Logout must not fail because token cleanup did.
    }
  }

  Future<void> _refreshRegistrationFromSession() async {
    debugPrint('[Push] _refreshRegistrationFromSession() called');
    if (!_initialized) {
      debugPrint('[Push] _refreshRegistrationFromSession aborted: not initialized');
      return;
    }
    if (AuthStore.instance.session?.actorType != ActorType.patient) {
      debugPrint('[Push] _refreshRegistrationFromSession aborted: not a patient actor');
      return;
    }

    try {
      debugPrint('[Push] Calling _messaging.getToken()...');
      final token = await _messaging.getToken();
      debugPrint('[Push] _messaging.getToken() returned: ${token != null ? _maskToken(token) : 'null'}');
      if (token == null || token.isEmpty) {
        debugPrint('[Push] FCM token is null or empty, aborting registration.');
        return;
      }
      await _registerToken(token);
    } catch (e, stackTrace) {
      debugPrint('[Push] Failed to get FCM token: $e');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _registerToken(String token) async {
    final session = AuthStore.instance.session;
    debugPrint('[Push] _registerToken() called. token=${_maskToken(token)}, session=${session?.actorType}');
    if (session?.actorType != ActorType.patient) return;
    if (_registeredToken == token) {
      debugPrint('[Push] Token already registered, skipping API call.');
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint(
          '[Push] POST /api/v1/patients/device-tokens platform=${defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android'} token=${_maskToken(token)}',
        );
      }
      await ApiClient.instance.post(
        '/api/v1/patients/device-tokens',
        data: {
          'token': token,
          'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        },
      );
      _registeredToken = token;
      if (kDebugMode) {
        debugPrint('[Push] POST /api/v1/patients/device-tokens success');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Push] POST /api/v1/patients/device-tokens failed: $e');
      }
      debugPrint('Failed to register FCM token: $e');
    }
  }

  String _maskToken(String token) {
    if (token.length <= 12) return token;
    return '${token.substring(0, 6)}...${token.substring(token.length - 6)}';
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _configureLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        _handleTapFromPayload(payload);
      },
    );

    final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_androidChannel);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: _encodePayload(message.data),
    );
  }

  void _handleTap(RemoteMessage message) {
    _onTap?.call(message.data);
  }

  void _handleTapFromPayload(String payload) {
    try {
      final data = Map<String, dynamic>.from(<String, dynamic>{});
      for (final entry in payload.split('&')) {
        if (entry.isEmpty || !entry.contains('=')) continue;
        final parts = entry.split('=');
        if (parts.length < 2) continue;
        data[Uri.decodeComponent(parts.first)] = Uri.decodeComponent(parts.sublist(1).join('='));
      }
      _onTap?.call(data);
    } catch (_) {
      _onTap?.call(const <String, dynamic>{});
    }
  }

  String _encodePayload(Map<String, dynamic> data) {
    return data.entries
        .map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}')
        .join('&');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}