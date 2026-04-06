import 'app/env/app_flavor.dart';
import 'bootstrap.dart';

Future<void> main() async {
  await bootstrap(flavor: AppFlavor.prod);
}
