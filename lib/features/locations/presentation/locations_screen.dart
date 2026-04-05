import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/extensions/context_l10n.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/locations_repository.dart';

class LocationsScreen extends ConsumerStatefulWidget {
  const LocationsScreen({super.key});

  @override
  ConsumerState<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends ConsumerState<LocationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(locationsProvider));
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);
    final selected = ref.watch(selectedLocationControllerProvider).selectedCode;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.locationsTitle)),
      body: locationsAsync.when(
        data: (locations) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(locationsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: locations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final location = locations[index];
              return AppCard(
                onTap: () => ref.read(selectedLocationControllerProvider).select(location.code),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.localizedName(context.l10n.localeName),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              StatusBadge(label: location.status),
                              if (location.recommended)
                                StatusBadge(label: context.l10n.recommended),
                              if (location.reserve)
                                StatusBadge(label: context.l10n.reserve),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: location.code,
                      groupValue: selected,
                      onChanged: (_) => ref.read(selectedLocationControllerProvider).select(location.code),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        loading: LoadingView.new,
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(locationsProvider),
        ),
      ),
    );
  }
}
