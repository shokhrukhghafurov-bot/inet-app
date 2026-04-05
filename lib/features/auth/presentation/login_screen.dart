import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final config = configAsync.value;
    final isLoading = session.status == SessionStatus.initializing;

    return Scaffold(
      body: Stack(
        children: [
          const _LoginBackground(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: _LanguageSwitcher(
                        languageCode: localeController.locale.languageCode,
                        onLanguageSelected: localeController.setLanguageCode,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _HeroHeader(appName: config?.appName ?? 'INET'),
                    const SizedBox(height: 28),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            icon: Icons.key_rounded,
                            title: context.l10n.loginWithCode,
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _codeController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submitCode(),
                            decoration: InputDecoration(
                              labelText: context.l10n.oneTimeCode,
                              hintText: 'token / code',
                            ),
                          ),
                          const SizedBox(height: 18),
                          PrimaryButton(
                            label: isLoading
                                ? context.l10n.loading
                                : context.l10n.continueLabel,
                            onPressed: isLoading ? null : _submitCode,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            icon: Icons.telegram,
                            title: context.l10n.telegramLogin,
                          ),
                          const SizedBox(height: 10),
                          Text(context.l10n.telegramLoginHint),
                          const SizedBox(height: 18),
                          PrimaryButton(
                            label: context.l10n.openBot,
                            onPressed: () => _openUrl(_botUrl(config)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _botUrl(AppConfig? config) {
    return config?.botUrl.isNotEmpty == true
        ? config!.botUrl
        : ref.read(appConfigRepositoryProvider).fallbackBotUrl();
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF06070A), Color(0xFF050608)],
              ),
            ),
          ),
        ),
        Positioned(
          top: -80,
          left: -40,
          child: _GlowOrb(
            size: 220,
            color: const Color(0x3322C55E),
          ),
        ),
        Positioned(
          top: 120,
          right: -70,
          child: _GlowOrb(
            size: 190,
            color: const Color(0x1F60A5FA),
          ),
        ),
        Positioned(
          bottom: -110,
          right: -10,
          child: _GlowOrb(
            size: 240,
            color: const Color(0x1A22C55E),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.appName});

  final String appName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF16301E), Color(0xFF22C55E)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3322C55E),
                blurRadius: 28,
                spreadRadius: 2,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.shield_rounded,
            size: 40,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          appName,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 38,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.loginSubtitle,
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          child: Icon(icon, size: 22, color: const Color(0xFF22C55E)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ],
    );
  }
}

class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher({
    required this.languageCode,
    required this.onLanguageSelected,
  });

  final String languageCode;
  final ValueChanged<String> onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageChip(
            label: 'RU',
            selected: languageCode == 'ru',
            onTap: () => onLanguageSelected('ru'),
          ),
          const SizedBox(width: 6),
          _LanguageChip(
            label: 'EN',
            selected: languageCode == 'en',
            onTap: () => onLanguageSelected('en'),
          ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF22C55E) : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
