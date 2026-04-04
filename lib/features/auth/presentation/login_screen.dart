import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/env/app_env.dart';
import '../../../core/models/app_config.dart';
import '../../../shared/extensions/context_l10n.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../app_config/data/app_config_repository.dart';
import '../../settings/application/locale_controller.dart';
import '../application/session_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      return;
    }

    try {
      await ref.read(sessionControllerProvider).loginWithCode(code);
    } catch (_) {
      if (!mounted) {
        return;
      }
      final message = ref.read(sessionControllerProvider).errorMessage ??
          context.l10n.loginFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final configAsync = ref.watch(appConfigProvider);
    final localeController = ref.watch(localeControllerProvider);
    final env = ref.watch(appEnvProvider);
    final config = configAsync.value;
    final isLoading = session.status == SessionStatus.initializing;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 24),
                Text(
                  config?.appName ?? 'INET',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.loginSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.loginWithCode,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _codeController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submitCode(),
                        decoration: InputDecoration(
                          labelText: context.l10n.oneTimeCode,
                          hintText: 'code / token',
                        ),
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: isLoading
                            ? context.l10n.loading
                            : context.l10n.continueLabel,
                        onPressed: isLoading ? null : _submitCode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.telegramLogin,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(context.l10n.telegramLoginHint),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: context.l10n.openBot,
                        onPressed: () => _openUrl(_botUrl(config)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (env.isDev) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Dev shell: используйте код 111111 / mock, если backend auth ещё не готов.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ChoiceChip(
                      label: const Text('RU'),
                      selected: localeController.locale.languageCode == 'ru',
                      onSelected: (_) => localeController.setLanguageCode('ru'),
                    ),
                    ChoiceChip(
                      label: const Text('EN'),
                      selected: localeController.locale.languageCode == 'en',
                      onSelected: (_) => localeController.setLanguageCode('en'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _botUrl(AppConfig? config) {
    return config?.botUrl.isNotEmpty == true
        ? config!.botUrl
        : ref.read(appConfigRepositoryProvider).fallbackBotUrl();
  }
}
