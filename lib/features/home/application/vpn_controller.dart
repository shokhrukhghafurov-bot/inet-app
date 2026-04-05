import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/vpn/vless_config.dart';
import '../../../core/vpn/vpn_access_repository.dart';
import '../../../core/vpn/vpn_bridge.dart';
import '../../../core/vpn/vpn_snapshot.dart';

enum VpnConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  unsupported,
}

final vpnControllerProvider = ChangeNotifierProvider<VpnController>((ref) {
  final controller = VpnController(
    VpnBridge(),
    ref.watch(vpnAccessRepositoryProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

class VpnController extends ChangeNotifier with WidgetsBindingObserver {
  VpnController(this._bridge, this._vpnAccessRepository) {
    WidgetsBinding.instance.addObserver(this);
  }

  final VpnBridge _bridge;
  final VpnAccessRepository _vpnAccessRepository;

  VpnConnectionStatus _status = VpnConnectionStatus.disconnected;
  String? _errorMessage;
  DateTime? _connectedAt;
  Duration _sessionDuration = Duration.zero;
  Timer? _ticker;
  Timer? _poller;
  String? _lastLocationCode;
  VlessConfig? _lastConfig;
  bool _reconnectOnLaunch = false;
  bool _disposed = false;
  bool _foreground = true;

  VpnConnectionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  DateTime? get connectedAt => _connectedAt;
  Duration get sessionDuration => _sessionDuration;
  String? get lastLocationCode => _lastLocationCode;
  bool get reconnectOnLaunch => _reconnectOnLaunch;
  VlessConfig? get lastConfig => _lastConfig;

  Future<void> refreshStatus() async {
    try {
      final snapshot = await _bridge.snapshot();
      _applySnapshot(snapshot);
    } on MissingPluginException {
      _status = VpnConnectionStatus.unsupported;
      _errorMessage = 'Native VPN layer is not connected yet.';
      _stopTicker(resetDuration: false);
      _stopPolling();
      _notify();
    } catch (_) {
      try {
        final raw = await _bridge.status();
        _status = _map(raw);
        if (_status == VpnConnectionStatus.connected) {
          _connectedAt ??= DateTime.now();
          _errorMessage = null;
          _startTicker();
        } else {
          _stopTicker(resetDuration: _status == VpnConnectionStatus.disconnected);
        }
        _syncPolling();
        _notify();
      } on MissingPluginException {
        _status = VpnConnectionStatus.unsupported;
        _errorMessage = 'Native VPN layer is not connected yet.';
        _stopTicker(resetDuration: false);
        _stopPolling();
        _notify();
      } catch (error) {
        _errorMessage = error.toString();
        _notify();
      }
    }
  }

  Future<void> connect(String locationCode) async {
    _status = VpnConnectionStatus.connecting;
    _errorMessage = null;
    _lastLocationCode = locationCode;
    _syncPolling(force: true);
    _notify();

    try {
      final config = await _vpnAccessRepository.fetchVlessConfig(locationCode);
      if (!config.isComplete) {
        throw StateError('Backend returned incomplete VLESS config for $locationCode');
      }
      _lastConfig = config;
      _lastLocationCode = config.locationCode;
      await _bridge.connect(config: config);
      await refreshStatus();
    } on MissingPluginException {
      _status = VpnConnectionStatus.unsupported;
      _errorMessage = 'Implement Android VpnService / iOS Packet Tunnel next.';
      _stopPolling();
      _notify();
    } catch (error) {
      _status = VpnConnectionStatus.disconnected;
      _errorMessage = error.toString();
      _stopTicker(resetDuration: true);
      _syncPolling();
      _notify();
    }
  }

  Future<void> disconnect() async {
    _status = VpnConnectionStatus.disconnecting;
    _errorMessage = null;
    _syncPolling(force: true);
    _notify();

    try {
      await _bridge.disconnect();
      await refreshStatus();
    } on MissingPluginException {
      _status = VpnConnectionStatus.unsupported;
      _errorMessage = 'Implement Android VpnService / iOS Packet Tunnel next.';
      _stopPolling();
      _notify();
    } catch (error) {
      _status = VpnConnectionStatus.connected;
      _errorMessage = error.toString();
      _syncPolling(force: true);
      _notify();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
        unawaited(_bridge.notifyAppResumed());
        unawaited(refreshStatus());
        return;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _foreground = false;
        unawaited(_bridge.notifyAppBackgrounded());
        _stopPolling();
        return;
    }
  }

  void _applySnapshot(VpnSnapshot snapshot) {
    _status = _map(snapshot.status);
    _errorMessage = snapshot.errorMessage;
    _lastLocationCode = snapshot.locationCode ?? _lastLocationCode;
    _reconnectOnLaunch = snapshot.reconnectOnLaunch;

    if (_status == VpnConnectionStatus.connected) {
      _connectedAt = snapshot.connectedAt ?? _connectedAt ?? DateTime.now();
      _startTicker();
    } else {
      final resetDuration = _status == VpnConnectionStatus.disconnected;
      _stopTicker(resetDuration: resetDuration);
      if (!resetDuration && snapshot.connectedAt != null) {
        _connectedAt = snapshot.connectedAt;
      }
    }

    _syncPolling();
    _notify();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectedAt == null) {
        return;
      }
      _sessionDuration = DateTime.now().difference(_connectedAt!);
      _notify();
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

  void _syncPolling({bool force = false}) {
    final shouldPoll = _foreground &&
        (_status == VpnConnectionStatus.connecting ||
            _status == VpnConnectionStatus.connected ||
            _status == VpnConnectionStatus.disconnecting ||
            force);

    if (!shouldPoll) {
      _stopPolling();
      return;
    }

    _poller ??= Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(refreshStatus());
    });
  }

  void _stopPolling() {
    _poller?.cancel();
    _poller = null;
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

  void _notify() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _stopPolling();
    super.dispose();
  }
}
