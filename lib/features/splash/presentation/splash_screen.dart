import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/session_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    // Всё, что нужно от provider, считываем до await
    final sessionController = ref.read(sessionControllerProvider);

    await Future<void>.delayed(const Duration(milliseconds: 300));
    await sessionController.restoreSession();

    if (!mounted) return;

    switch (sessionController.status) {
      case SessionStatus.authenticated:
        context.go('/home');
        break;
      case SessionStatus.unauthenticated:
      case SessionStatus.initializing:
        context.go('/login');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
