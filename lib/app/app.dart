import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/deep_links/deep_link_listener.dart';
import '../features/settings/application/locale_controller.dart';
import '../shared/extensions/context_l10n.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class InetApp extends ConsumerStatefulWidget {
  const InetApp({super.key});

  @override
  ConsumerState<InetApp> createState() => _InetAppState();
}

class _InetAppState extends ConsumerState<InetApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(localeControllerProvider).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final localeController = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      title: 'INET',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      locale: localeController.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationsDelegates,
      routerConfig: router,
      builder: (context, child) {
        return DeepLinkListener(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
