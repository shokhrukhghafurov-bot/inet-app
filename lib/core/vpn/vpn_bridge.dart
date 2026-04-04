import 'package:flutter/services.dart';

class VpnBridge {
  static const _channel = MethodChannel('inet/vpn');

  Future<void> connect({required String locationCode}) {
    return _channel.invokeMethod<void>('connect', {
      'locationCode': locationCode,
    });
  }

  Future<void> disconnect() {
    return _channel.invokeMethod<void>('disconnect');
  }

  Future<String> status() async {
    final value = await _channel.invokeMethod<String>('status');
    return value ?? 'disconnected';
  }
}
