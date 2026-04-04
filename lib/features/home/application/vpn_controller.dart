import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/vpn/vpn_bridge.dart';

enum VpnConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  unsupported,
}

final vpnControllerProvider = ChangeNotifierProvider<VpnController>((ref) {
  final controller = VpnController(VpnBridge());
  ref.onDispose(controller.dispose);
  return controller;
});

class VpnController extends ChangeNotifier {
  VpnController(this._bridge);

  final VpnBridge _bridge;

  VpnConnectionStatus _status = VpnConnectionStatus.disconnected;
  String? _errorMessage;
  DateTime? _connectedAt;
  Duration _sessionDuration = Duration.zero;
  Timer? _ticker;

  VpnConnectionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  DateTime? get connectedAt => _connectedAt;
  Duration get sessionDuration => _sessionDuration;

  Future<void> refreshStatus() async {
    try {
      final raw = await _bridge.status();
      _status = _map(raw);
      _errorMessage = null;
      if (_status == VpnConnectionStatus.connected) {
        _connectedAt ??= DateTime.now();
        _startTicker();
      } else {
        _stopTicker(resetDuration: _status == VpnConnectionStatus.disconnected);
      }
    } on MissingPluginException {
      _status = VpnConnectionStatus.unsupported;
      _errorMessage = 'Native VPN layer is not connected yet.';
    }
    notifyListeners();
  }

  Future<void> connect(String locationCode) async {
    _status = VpnConnectionStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bridge.connect(locationCode: locationCode);
      _status = VpnConnectionStatus.connected;
      _connectedAt = DateTime.now();
      _sessionDuration = Duration.zero;
      _startTicker();
    } on MissingPluginException {
      _status = VpnConnectionStatus.unsupported;
      _errorMessage = 'Implement Android VpnService / iOS Packet Tunnel next.';
    } catch (error) {
      _status = VpnConnectionStatus.disconnected;
      _errorMessage = error.toString();
      _stopTicker(resetDuration: true);
    }

    notifyListeners();
  }

  Future<void> disconnect() async {
    _status = VpnConnectionStatus.disconnecting;
    notifyListeners();

    try {
      await _bridge.disconnect();
      _status = VpnConnectionStatus.disconnected;
      _errorMessage = null;
      _stopTicker(resetDuration: true);
    } on MissingPluginException {
      _status = VpnConnectionStatus.unsupported;
      _errorMessage = 'Implement Android VpnService / iOS Packet Tunnel next.';
    } catch (error) {
      _status = VpnConnectionStatus.connected;
      _errorMessage = error.toString();
    }

    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectedAt == null) {
        return;
      }
      _sessionDuration = DateTime.now().difference(_connectedAt!);
      notifyListeners();
    });
  }

  void _stopTicker({required bool resetDuration}) {
    _ticker?.cancel();
    _ticker = null;
    if (resetDuration) {
      _connectedAt = null;
      _sessionDuration = Duration.zero;
    }
  }

  VpnConnectionStatus _map(String raw) {
    return switch (raw) {
      'connected' => VpnConnectionStatus.connected,
      'connecting' => VpnConnectionStatus.connecting,
      'disconnecting' => VpnConnectionStatus.disconnecting,
      'unsupported' => VpnConnectionStatus.unsupported,
      _ => VpnConnectionStatus.disconnected,
    };
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
