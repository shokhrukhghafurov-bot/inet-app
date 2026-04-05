import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/location.dart';
import '../../../core/models/subscription.dart';
import '../../../shared/extensions/context_l10n.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../app_config/data/app_config_repository.dart';
import '../../devices/data/devices_repository.dart';
import '../../locations/data/locations_repository.dart';
import '../../subscription/data/subscription_repository.dart';
import '../application/vpn_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(vpnControllerProvider).refreshStatus());
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);
    final subscriptionAsync = ref.watch(subscriptionProvider);
    final devicesAsync = ref.watch(devicesProvider);
    final configAsync = ref.watch(appConfigProvider);
    final selectedLocationController = ref.watch(selectedLocationControllerProvider);
    final vpnController = ref.watch(vpnControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('INET'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(locationsProvider);
          ref.invalidate(subscriptionProvider);
          ref.invalidate(devicesProvider);
          ref.invalidate(appConfigProvider);
          await ref.read(vpnControllerProvider).refreshStatus();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.connectionStatus,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusBadge(label: _statusLabel(context, vpnController.status)),
                      Text(
                        _statusDescription(context, vpnController.status),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  subscriptionAsync.when(
                    data: (subscription) => Text(
                      _subscriptionSummary(context, subscription),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: vpnController.status == VpnConnectionStatus.connected
                        ? context.l10n.disconnect
                        : context.l10n.connect,
                    onPressed: () => _toggleConnection(
                      context,
                      locationsAsync.value ?? const [],
                      subscriptionAsync.value,
                      selectedLocationController.current(locationsAsync.value ?? const []),
                    ),
                  ),
                  if (vpnController.errorMessage case final error?) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error.withOpacity(0.28),
                        ),
                      ),
                      child: Text(error),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            locationsAsync.when(
              data: (locations) {
                final current = selectedLocationController.current(locations);
                return AppCard(
                  onTap: () => context.go('/locations'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.currentLocation,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        current?.localizedName(context.l10n.localeName) ?? context.l10n.notSelected,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Режим: ${_modeLabel(current, context)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                      if (vpnController.status == VpnConnectionStatus.connected) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Таймер: ${_formatDuration(vpnController.sessionDuration)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ],
                  ),
                );
              },
              loading: LoadingView.new,
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(locationsProvider),
              ),
            ),
            const SizedBox(height: 16),
            subscriptionAsync.when(
              data: (subscription) => AppCard(
                onTap: () => context.go('/subscription'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.subscriptionTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _subscriptionTitle(context, subscription),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text('${context.l10n.expiresAt}: ${_formatDate(subscription?.expiresAt, context)}'),
                    const SizedBox(height: 6),
                    Text(_devicesSummary(subscription)),
                  ],
                ),
              ),
              loading: LoadingView.new,
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(subscriptionProvider),
              ),
            ),
            const SizedBox(height: 16),
            devicesAsync.when(
              data: (devices) => AppCard(
                onTap: () => context.go('/devices'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.devicesTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('${context.l10n.usedDevices}: ${devices.length}'),
                  ],
                ),
              ),
              loading: LoadingView.new,
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(devicesProvider),
              ),
            ),
            const SizedBox(height: 16),
            configAsync.when(
              data: (config) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _QuickActionButton(
                    label: context.l10n.locationsTitle,
                    icon: Icons.public,
                    onTap: () => context.go('/locations'),
                  ),
                  _QuickActionButton(
                    label: context.l10n.subscriptionTitle,
                    icon: Icons.workspace_premium_outlined,
                    onTap: () => context.go('/subscription'),
                  ),
                  _QuickActionButton(
                    label: context.l10n.devicesTitle,
                    icon: Icons.devices_outlined,
                    onTap: () => context.go('/devices'),
                  ),
                  _QuickActionButton(
                    label: context.l10n.support,
                    icon: Icons.support_agent,
                    onTap: () => _launch(config.supportUrl),
                  ),
                  _QuickActionButton(
                    label: context.l10n.openBot,
                    icon: Icons.open_in_new,
                    onTap: () => _launch(config.botUrl),
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleConnection(
    BuildContext context,
    List<VpnLocation> locations,
    Subscription? subscription,
    VpnLocation? current,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final vpn = ref.read(vpnControllerProvider);

    if (vpn.status == VpnConnectionStatus.connected) {
      await vpn.disconnect();
      return;
    }

    if (subscription == null || !subscription.isActive) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Подписка не активна. Открой экран подписки для продления.')),
      );
      return;
    }

    if (current == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Сначала выбери локацию.')),
      );
      return;
    }

    try {
      await ref.read(devicesRepositoryProvider).registerCurrentDevice();
      ref.invalidate(devicesProvider);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }

    await vpn.connect(current.code);
  }

  static String _statusLabel(BuildContext context, VpnConnectionStatus status) {
    return switch (status) {
      VpnConnectionStatus.connected => context.l10n.connected,
      VpnConnectionStatus.connecting => context.l10n.connecting,
      VpnConnectionStatus.disconnecting => context.l10n.disconnecting,
      VpnConnectionStatus.unsupported => context.l10n.nativePending,
      VpnConnectionStatus.disconnected => context.l10n.disconnected,
    };
  }

  static String _statusDescription(BuildContext context, VpnConnectionStatus status) {
    return switch (status) {
      VpnConnectionStatus.connected => 'VPN активно и готово к работе.',
      VpnConnectionStatus.connecting => 'Подождите немного, соединение устанавливается.',
      VpnConnectionStatus.disconnecting => 'Соединение завершается.',
      VpnConnectionStatus.unsupported => 'Нативный VPN-модуль ещё не подключён к приложению.',
      VpnConnectionStatus.disconnected => 'Выберите локацию и нажмите кнопку подключения.',
    };
  }

  static String _subscriptionSummary(BuildContext context, Subscription? subscription) {
    if (subscription == null) {
      return context.l10n.noSubscription;
    }
    final plan = subscription.localizedPlanName(context.l10n.localeName);
    final date = _formatDate(subscription.expiresAt, context);
    return '$plan · $date';
  }

  static String _subscriptionTitle(BuildContext context, Subscription? subscription) {
    if (subscription == null) {
      return context.l10n.noSubscription;
    }
    final value = subscription.localizedPlanName(context.l10n.localeName);
    return value.isEmpty ? context.l10n.noSubscription : value;
  }

  static String _devicesSummary(Subscription? subscription) {
    final used = subscription?.devicesUsed ?? 0;
    final limit = subscription?.deviceLimit ?? 0;
    if (limit <= 0) {
      return 'Устройств: —';
    }
    return 'Устройств: $used из $limit';
  }

  static String _modeLabel(VpnLocation? current, BuildContext context) {
    if (current == null) {
      return context.l10n.notSelected;
    }
    if (current.recommended) {
      return 'Авто | Самый быстрый';
    }
    if (current.reserve) {
      return 'Авто | Резервный';
    }
    return current.localizedName(context.l10n.localeName);
  }

  static String _formatDate(DateTime? date, BuildContext context) {
    if (date == null) {
      return context.l10n.notAvailable;
    }
    return DateFormat.yMMMd(context.l10n.localeName).add_Hm().format(date.toLocal());
  }

  static String _formatDuration(Duration value) {
    final hours = value.inHours.toString().padLeft(2, '0');
    final minutes = (value.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  static Future<void> _launch(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width > 500 ? 180 : (MediaQuery.of(context).size.width - 52) / 2,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(label),
        ),
      ),
    );
  }
}
