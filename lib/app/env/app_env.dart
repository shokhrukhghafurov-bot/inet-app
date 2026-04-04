import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_flavor.dart';

final appEnvProvider = Provider<AppEnv>((ref) {
  throw UnimplementedError('AppEnv must be overridden in bootstrap().');
});

class AppEnv {
  const AppEnv({
    required this.flavor,
    required this.baseUrl,
    required this.botUrl,
    required this.supportUrl,
    required this.appScheme,
    required this.appName,
  });

  final AppFlavor flavor;
  final String baseUrl;
  final String botUrl;
  final String supportUrl;
  final String appScheme;
  final String appName;

  bool get isDev => flavor == AppFlavor.dev;

  factory AppEnv.fromFlavor(AppFlavor flavor) {
    switch (flavor) {
      case AppFlavor.dev:
        return const AppEnv(
          flavor: AppFlavor.dev,
          baseUrl: String.fromEnvironment(
            'DEV_BASE_URL',
            defaultValue: 'http://10.0.2.2:8000',
          ),
          botUrl: String.fromEnvironment(
            'DEV_BOT_URL',
            defaultValue: 'https://t.me/inet_dev_bot',
          ),
          supportUrl: String.fromEnvironment(
            'DEV_SUPPORT_URL',
            defaultValue: 'https://t.me/inet_support',
          ),
          appScheme: 'inet',
          appName: 'INET Dev',
        );
      case AppFlavor.prod:
        return const AppEnv(
          flavor: AppFlavor.prod,
          baseUrl: String.fromEnvironment(
            'PROD_BASE_URL',
            defaultValue: 'https://api.example.com',
          ),
          botUrl: String.fromEnvironment(
            'PROD_BOT_URL',
            defaultValue: 'https://t.me/inet_bot',
          ),
          supportUrl: String.fromEnvironment(
            'PROD_SUPPORT_URL',
            defaultValue: 'https://t.me/inet_support',
          ),
          appScheme: 'inet',
          appName: 'INET',
        );
    }
  }
}
