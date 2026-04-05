import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/extensions/context_l10n.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../data/devices_repository.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);
    final repository = ref.watch(devicesRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.devicesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await repository.registerCurrentDevice();
          ref.invalidate(devicesProvider);
        },
        label: Text(context.l10n.registerDevice),
        icon: const Icon(Icons.add),
      ),
      body: devicesAsync.when(
        data: (devices) => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: devices.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final device = devices[index];
            return AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('${context.l10n.platform}: ${device.platform ?? '-'}'),
                        const SizedBox(height: 6),
                        Text(
                          '${context.l10n.lastActive}: ${_formatDate(device.lastActiveAt, context)}',
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await repository.removeDevice(device.id);
                      ref.invalidate(devicesProvider);
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            );
          },
        ),
        loading: LoadingView.new,
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(devicesProvider),
        ),
      ),
    );
  }

  static String _formatDate(DateTime? date, BuildContext context) {
    if (date == null) {
      return context.l10n.notAvailable;
    }
    return DateFormat.yMMMd(context.l10n.localeName).add_Hm().format(date.toLocal());
  }
}
