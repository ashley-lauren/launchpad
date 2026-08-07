import 'package:flutter_test/flutter_test.dart';
import 'package:launchpad/src/services/supabase_config.dart';

void main() {
  group('resolveSupabaseConfig', () {
    test('prefers explicit values when provided', () {
      final config = resolveSupabaseConfig(
        explicitUrl: 'https://explicit.example',
        explicitAnonKey: 'explicit-key',
        envUrl: 'https://env.example',
        envAnonKey: 'env-key',
        envPublishableKey: 'env-publishable-key',
      );

      expect(config.url, 'https://explicit.example');
      expect(config.anonKey, 'explicit-key');
    });

    test('uses publishable key from env when explicit anon key is empty', () {
      final config = resolveSupabaseConfig(
        explicitUrl: '',
        explicitAnonKey: '',
        envUrl: 'https://env.example',
        envAnonKey: 'env-key',
        envPublishableKey: 'env-publishable-key',
      );

      expect(config.url, 'https://env.example');
      expect(config.anonKey, 'env-publishable-key');
    });
  });
}
