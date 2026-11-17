import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/push_messaging.dart';

/// [PushMessaging] con Firebase Cloud Messaging.
///
/// Firebase se configura con `android/app/google-services.json` (y
/// `ios/Runner/GoogleService-Info.plist`). Sin ese archivo `Firebase.initializeApp`
/// falla, [start] devuelve `false` y la app sigue sin push.
///
/// Usa el token de registro clásico (`getToken`/`onTokenRefresh`/`deleteToken`),
/// que `firebase_messaging` 17 marca como obsoleto en favor de `register()` y el
/// Installation ID. El backend envía con la API HTTP v1 al campo `token`, que es
/// el contrato documentado para ese token; por eso se mantiene aquí.
class FirebasePushMessaging implements PushMessaging {
  bool? _ready;

  static PushNotice _notice(RemoteMessage m) => PushNotice(
    title: m.notification?.title,
    body: m.notification?.body,
    route: m.data['ruta'] as String?,
  );

  @override
  String get platform => Platform.isIOS ? 'ios' : 'android';

  @override
  Future<bool> start() async {
    if (_ready != null) return _ready!;
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return _ready = false;
    }
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final settings = await FirebaseMessaging.instance.requestPermission();
      _ready =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('Push desactivado (Firebase sin configurar): $e');
      _ready = false;
    }
    return _ready!;
  }

  @override
  Future<String?> token() async {
    if (_ready != true) return null;
    try {
      // ignore: deprecated_member_use
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('No se obtuvo el token FCM: $e');
      return null;
    }
  }

  @override
  Stream<String> get onTokenRefresh => _ready == true
      // ignore: deprecated_member_use
      ? FirebaseMessaging.instance.onTokenRefresh
      : const Stream.empty();

  @override
  Stream<PushNotice> get onForeground => _ready == true
      ? FirebaseMessaging.onMessage.map(_notice)
      : const Stream.empty();

  @override
  Stream<PushNotice> get onOpened => _ready == true
      ? FirebaseMessaging.onMessageOpenedApp.map(_notice)
      : const Stream.empty();

  @override
  Future<PushNotice?> initialNotice() async {
    if (_ready != true) return null;
    final message = await FirebaseMessaging.instance.getInitialMessage();
    return message == null ? null : _notice(message);
  }

  @override
  Future<void> deleteToken() async {
    if (_ready != true) return;
    try {
      // ignore: deprecated_member_use
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('No se pudo borrar el token FCM: $e');
    }
  }
}
