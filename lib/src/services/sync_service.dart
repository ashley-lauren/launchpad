import 'package:flutter/foundation.dart';

import '../data/local_repository.dart';
import '../data/supabase_repository.dart';

enum SyncStatus { onlineSynced, offlineLocal, syncPending, syncing }

class SyncService extends ChangeNotifier {
  SyncService({required this.localRepository, required this.remoteRepository});

  final LocalRepository localRepository;
  final SupabaseRepository? remoteRepository;

  SyncStatus _status = SyncStatus.offlineLocal;
  bool _isSyncing = false;

  SyncStatus get status => _status;
  bool get hasRemote => remoteRepository != null;

  Future<void> markPending() async {
    _status = remoteRepository == null
        ? SyncStatus.offlineLocal
        : SyncStatus.syncPending;
    notifyListeners();
    await trySync();
  }

  Future<void> trySync() async {
    if (_isSyncing || remoteRepository == null) {
      _status = SyncStatus.offlineLocal;
      notifyListeners();
      return;
    }
    _isSyncing = true;
    _status = SyncStatus.syncing;
    notifyListeners();

    final syncedSubmissionIds = <String>{};
    final syncedPointIds = <String>{};
    try {
      final state = await localRepository.loadState();
      await remoteRepository!.saveWarmup(state.warmup);
      await remoteRepository!.saveTeams(state.teams);

      for (final submission in state.submissions.where(
        (item) => item.syncedAt == null,
      )) {
        await remoteRepository!.saveSubmission(submission);
        syncedSubmissionIds.add(submission.clientGeneratedId);
      }
      for (final event in state.pointEvents.where(
        (item) => item.syncedAt == null,
      )) {
        await remoteRepository!.savePointEvent(event);
        syncedPointIds.add(event.clientGeneratedId);
      }

      await localRepository.markSynced(
        submissionClientIds: syncedSubmissionIds,
        pointEventClientIds: syncedPointIds,
      );
      _status = SyncStatus.onlineSynced;
    } catch (_) {
      _status = SyncStatus.syncPending;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
