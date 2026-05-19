import 'package:flutter/material.dart';

import '../../services/sync_service.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SyncStatus.onlineSynced => ('Online: synced', const Color(0xFF7EE787)),
      SyncStatus.offlineLocal => (
          'Offline: local mode',
          const Color(0xFFFFC857),
        ),
      SyncStatus.syncPending => ('Sync pending', const Color(0xFFFFC857)),
      SyncStatus.syncing => ('Syncing...', const Color(0xFF79C0FF)),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.52)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
