import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/env/app_env.dart';
import 'app/env/app_flavor.dart';

Future<void> bootstrap({required AppFlavor flavor}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer(
    overrides: [
      appEnvProvider.overrideWithValue(AppEnv.fromFlavor(flavor)),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const InetApp(),
    ),
  );
}
