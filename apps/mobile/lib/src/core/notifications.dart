import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'api.dart';
import 'push_messaging.dart';

/// How the resident is being reached.
enum AlertChannel {
  /// Push granted: they do not need to open the app at all.
  push,

  /// Push denied. Alerts degrade to an in-app banner rather than vanishing —
  /// a resident who refused notifications should still learn the auto is near
  /// while the app is open (Clarifications CHK039).
  inApp,
}

class AlertState {
  const AlertState({required this.channel, this.banner});

  final AlertChannel channel;
  final String? banner;

  AlertState copyWith({AlertChannel? channel, String? banner}) =>
      AlertState(channel: channel ?? this.channel, banner: banner);
}

class AlertController extends StateNotifier<AlertState> {
  AlertController(this._api, this._push) : super(const AlertState(channel: AlertChannel.inApp)) {
    _subscription = _push.foregroundMessages.listen(onMessage);
  }

  final Api _api;
  final PushMessaging _push;
  StreamSubscription<PushMessage>? _subscription;

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  /// Asks once, then reports which channel the resident actually has.
  Future<AlertChannel> requestPermission() async {
    final status = await Permission.notification.request();
    final channel = status.isGranted ? AlertChannel.push : AlertChannel.inApp;
    state = state.copyWith(channel: channel);
    return channel;
  }

  /// Called after sign-in: gets a device token and tells the server about it.
  ///
  /// Returns the channel actually available. Without a configured transport
  /// there is no token, so the resident stays on the in-app banner rather than
  /// believing alerts are on (FR-NOTIF-01).
  Future<AlertChannel> start() async {
    if (!_push.isConfigured) {
      state = state.copyWith(channel: AlertChannel.inApp);
      return AlertChannel.inApp;
    }

    final token = await _push.obtainToken();
    if (token == null) {
      state = state.copyWith(channel: AlertChannel.inApp);
      return AlertChannel.inApp;
    }

    await registerToken(token);
    state = state.copyWith(channel: AlertChannel.push);

    // A push may have launched the app; act on it before anything else.
    final launch = await _push.initialMessage();
    if (launch != null) onMessage(launch);

    return AlertChannel.push;
  }

  /// A push that arrived while the app was open. Android does not draw these
  /// itself, so the banner is the only thing the resident would see.
  void onMessage(PushMessage message) {
    if (!message.isArrivalRelated && message.kind != 'schedule_change') return;
    final text = message.body.isEmpty ? message.title : '${message.title} — ${message.body}';
    showBanner(text);
  }

  /// Registers the FCM token so the server can reach this device.
  Future<void> registerToken(String token) async {
    try {
      await _api.registerDeviceToken(token);
    } catch (error) {
      // Not fatal: the resident can still watch the live map, and the token
      // will register on the next launch.
      debugPrint('Could not register push token: $error');
    }
  }

  void showBanner(String message) => state = state.copyWith(banner: message);
  void dismissBanner() => state = state.copyWith(banner: null);
}

final alertProvider = StateNotifierProvider<AlertController, AlertState>(
  (ref) => AlertController(ref.watch(apiProvider), ref.watch(pushMessagingProvider)),
);
