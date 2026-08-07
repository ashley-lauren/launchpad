import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/data/local_repository.dart';
import 'src/data/supabase_repository.dart';
import 'src/services/classroom_state_service.dart';
import 'src/services/launchpad_controller.dart';
import 'src/services/supabase_config.dart';
import 'src/services/sync_service.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await dotenv.load(fileName: '.env');

  final prefs = await SharedPreferences.getInstance();
  final localRepository = LocalRepository(prefs);
  await localRepository.ensureSeeded();

  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  final supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
  final envUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final envAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  final envPublishableKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '';
  final config = resolveSupabaseConfig(
    explicitUrl: supabaseUrl,
    explicitAnonKey: supabaseAnonKey,
    envUrl: envUrl,
    envAnonKey: envAnonKey,
    envPublishableKey: envPublishableKey,
  );

  SupabaseRepository? remoteRepository;
  ClassroomStateService? classroomStateService;
  if (config.url.isNotEmpty && config.anonKey.isNotEmpty) {
    try {
      debugPrint('[Main] initializing Supabase with ${config.url}');
      await Supabase.initialize(
        url: config.url,
        publishableKey: config.anonKey,
      );
      remoteRepository = SupabaseRepository(Supabase.instance.client);
      classroomStateService = ClassroomStateService();
    } catch (error) {
      debugPrint('[Main] Supabase initialization failed: $error');
      remoteRepository = null;
      classroomStateService = null;
    }
  } else {
    debugPrint('[Main] Supabase credentials missing');
  }

  final syncService = SyncService(
    localRepository: localRepository,
    remoteRepository: remoteRepository,
  );

  final controller = LaunchpadController(
    localRepository: localRepository,
    syncService: syncService,
    classroomStateService: classroomStateService,
  );
  await controller.load();
  syncService.trySync();

  runApp(LaunchpadApp(controller: controller));
}
