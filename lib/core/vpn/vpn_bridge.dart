import 'package:flutter/services.dart';

import 'vless_config.dart';
import 'vpn_snapshot.dart';

class VpnBridge {
  static const _channel = MethodChannel('inet/vpn');

  Future<void> connect({required VlessConfig config}) {
    return _channel.invokeMethod<void>('connect', {
      'config': config.toMap(),
    });
  }

  Future<void> disconnect() {
    return _channel.invokeMethod<void>('disconnect');
  }

  Future<String> status() async {
    final value = await _channel.invokeMethod<String>('status');
    return value ?? 'disconnected';
  }

  Future<VpnSnapshot> snapshot() async {
    final value = await _channel.invokeMapMethod<Object?, Object?>('snapshot');
    return VpnSnapshot.fromMap(value);
  }

  Future<void> notifyAppResumed() {
    return _channel.invokeMethod<void>('appResumed');
  }

  Future<void> notifyAppBackgrounded() {
    return _channel.invokeMethod<void>('appBackgrounded');
  }
}
