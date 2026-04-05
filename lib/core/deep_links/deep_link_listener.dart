import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/session_controller.dart';
import '../../features/settings/application/locale_controller.dart';

class DeepLinkListener extends ConsumerStatefulWidget {
  const DeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends ConsumerState<DeepLinkListener> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;
  String? _lastCredential;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _bind();
  }

  Future<void> _bind() async {
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      await _handleUri(initialLink);
    }

    _subscription = _appLinks.uriLinkStream.listen((uri) async {
      await _handleUri(uri);
    });
  }

  Future<void> _handleUri(Uri uri) async {
    final token = uri.queryParameters['token'];
    final code = uri.queryParameters['code'];
    final language = uri.queryParameters['lang'];
    final credential = (token ?? code ?? '').trim();

    if (language == 'ru' || language == 'en') {
      await ref.read(localeControllerProvider).setLanguageCode(language!);
    }

    if (credential.isEmpty || credential == _lastCredential) {
      return;
    }

    _lastCredential = credential;

    try {
      if (token != null && token.isNotEmpty) {
        await ref.read(sessionControllerProvider).loginWithToken(token);
      } else {
        await ref.read(sessionControllerProvider).loginWithCode(code!);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deep link login failed.')),
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
