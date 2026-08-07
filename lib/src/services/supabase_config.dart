class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  final String url;
  final String anonKey;
}

SupabaseConfig resolveSupabaseConfig({
  required String explicitUrl,
  required String explicitAnonKey,
  required String envUrl,
  required String envAnonKey,
  required String envPublishableKey,
}) {
  final url = explicitUrl.isNotEmpty ? explicitUrl : envUrl;
  final anonKey = explicitAnonKey.isNotEmpty
      ? explicitAnonKey
      : envPublishableKey.isNotEmpty
          ? envPublishableKey
          : envAnonKey;

  return SupabaseConfig(url: url, anonKey: anonKey);
}
