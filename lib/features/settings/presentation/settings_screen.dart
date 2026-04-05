import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/env/app_env.dart';
import '../../../shared/extensions/context_l10n.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/setting_tile.dart';
import '../../app_config/data/app_config_repository.dart';
import '../../auth/application/session_controller.dart';
import '../application/locale_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeController = ref.watch(localeControllerProvider);
    final config = ref.watch(appConfigProvider).value;
    final env = ref.watch(appEnvProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              children: [
                SettingTile(
                  title: context.l10n.language,
                  subtitle: localeController.locale.languageCode.toUpperCase(),
                  trailing: DropdownButton<String>(
                    value: localeController.locale.languageCode,
                    items: const [
                      DropdownMenuItem(value: 'ru', child: Text('RU')),
                      DropdownMenuItem(value: 'en', child: Text('EN')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        localeController.setLanguageCode(value);
                      }
                    },
                  ),
                ),
                SettingTile(
                  title: context.l10n.devicesTitle,
                  subtitle: 'Управление устройствами',
                  onTap: () => context.go('/devices'),
                ),
                SettingTile(
                  title: context.l10n.support,
                  subtitle: config?.supportUrl ?? env.supportUrl,
                  onTap: () => _launch(config?.supportUrl ?? env.supportUrl),
                ),
                SettingTile(
                  title: context.l10n.openBot,
                  subtitle: config?.botUrl ?? env.botUrl,
                  onTap: () => _launch(config?.botUrl ?? env.botUrl),
                ),
                SettingTile(
                  title: context.l10n.version,
                  subtitle: '0.1.0+1',
                ),
                SettingTile(
                  title: context.l10n.environment,
                  subtitle: env.flavor.name,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => ref.read(sessionControllerProvider).logout(),
            icon: const Icon(Icons.logout),
            label: Text(context.l10n.logout),
          ),
        ],
      ),
    );
  }

  static Future<void> _launch(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
