import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/extensions/context_l10n.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../app_config/data/app_config_repository.dart';
import '../data/subscription_repository.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionProvider);
    final configAsync = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.subscriptionTitle)),
      body: subscriptionAsync.when(
        data: (subscription) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _planName(subscription, context),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text('${context.l10n.status}: ${subscription?.status ?? context.l10n.inactive}'),
                  const SizedBox(height: 8),
                  Text(
                    '${context.l10n.expiresAt}: ${_formatDate(subscription?.expiresAt, context)}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${context.l10n.deviceLimit}: ${subscription?.deviceLimit ?? '-'}',
                  ),
                  const SizedBox(height: 8),
                  Text('Устройств: ${subscription?.devicesUsed ?? 0} из ${subscription?.deviceLimit ?? 0}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.go('/devices'),
              icon: const Icon(Icons.devices_outlined),
              label: Text(context.l10n.devicesTitle),
            ),
            const SizedBox(height: 16),
            configAsync.when(
              data: (config) => Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _launch(config.botUrl),
                      child: Text(context.l10n.renewInBot),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _launch(config.supportUrl),
                      child: Text(context.l10n.support),
                    ),
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
        loading: LoadingView.new,
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(subscriptionProvider),
        ),
      ),
    );
  }

  static String _planName(dynamic subscription, BuildContext context) {
    if (subscription == null) {
      return context.l10n.noSubscription;
    }
    final value = subscription.localizedPlanName(context.l10n.localeName);
    return value.isEmpty ? context.l10n.noSubscription : value;
  }

  static String _formatDate(DateTime? date, BuildContext context) {
    if (date == null) {
      return context.l10n.notAvailable;
    }
    return DateFormat.yMMMd(context.l10n.localeName).add_Hm().format(date.toLocal());
  }

  static Future<void> _launch(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
