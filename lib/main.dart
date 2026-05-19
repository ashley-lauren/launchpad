import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/data/local_repository.dart';
import 'src/data/supabase_repository.dart';
import 'src/services/launchpad_controller.dart';
import 'src/services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final localRepository = LocalRepository(prefs);
  await localRepository.ensureSeeded();

  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  final supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

  SupabaseRepository? remoteRepository;
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      remoteRepository = SupabaseRepository(Supabase.instance.client);
    } catch (_) {
      remoteRepository = null;
    }
  }

  final syncService = SyncService(
    localRepository: localRepository,
    remoteRepository: remoteRepository,
  );

  final controller = LaunchpadController(
    localRepository: localRepository,
    syncService: syncService,
  );
  await controller.load();
  syncService.trySync();

  runApp(LaunchpadApp(controller: controller));
}
