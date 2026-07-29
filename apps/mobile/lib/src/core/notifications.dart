import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'api.dart';

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
  AlertController(this._api) : super(const AlertState(channel: AlertChannel.inApp));

  final Api _api;

  /// Asks once, then reports which channel the resident actually has.
  Future<AlertChannel> requestPermission() async {
    final status = await Permission.notification.request();
    final channel = status.isGranted ? AlertChannel.push : AlertChannel.inApp;
    state = state.copyWith(channel: channel);
    return channel;
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
  (ref) => AlertController(ref.watch(apiProvider)),
);
