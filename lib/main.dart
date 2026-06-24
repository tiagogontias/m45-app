import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'core/config.dart';
import 'core/routes.dart';
import 'core/theme.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';
import 'services/pocketbase_service.dart';
import 'services/sync_service.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton<PocketBaseService>(() => PocketBaseService());
  getIt.registerLazySingleton<LocalStorageService>(() => LocalStorageService());
  getIt.registerLazySingleton<SyncService>(
    () => SyncService(
      localStorage: getIt<LocalStorageService>(),
      pocketBase: getIt<PocketBaseService>(),
    ),
  );
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localStorage = LocalStorageService();
  await localStorage.init();

  setupDependencies();

  Future.microtask(() async {
    try {
      await getIt<NotificationService>().init();
      await getIt<SyncService>().syncPendingData();
    } catch (_) {}
  });

  runApp(const M45App());
}

class M45App extends StatelessWidget {
  const M45App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
