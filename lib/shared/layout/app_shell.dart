import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../extensions/context_l10n.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final index = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          final target = switch (value) {
            0 => '/home',
            1 => '/locations',
            2 => '/subscription',
            _ => '/settings',
          };
          context.go(target);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: context.l10n.homeTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.public),
            label: context.l10n.locationsTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.workspace_premium_outlined),
            label: context.l10n.subscriptionTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            label: context.l10n.settingsTitle,
          ),
        ],
      ),
    );
  }

  int _indexFromLocation(String value) {
    if (value.startsWith('/locations')) return 1;
    if (value.startsWith('/subscription')) return 2;
    if (value.startsWith('/settings') || value.startsWith('/devices')) return 3;
    return 0;
  }
}
