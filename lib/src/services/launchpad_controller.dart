import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/local_repository.dart';
import '../models/launchpad_models.dart';
import 'sync_service.dart';

class LaunchpadController extends ChangeNotifier {
  LaunchpadController({
    required this.localRepository,
    required this.syncService,
  }) {
    syncService.addListener(notifyListeners);
  }

  final LocalRepository localRepository;
  final SyncService syncService;
  final _uuid = const Uuid();

  LaunchpadState? _state;
  Timer? _ticker;
  int _secondsRemaining = 300;
  bool _timerRunning = false;

  LaunchpadState get state => _state!;
  int get secondsRemaining => _secondsRemaining;
  bool get timerRunning => _timerRunning;
  SyncStatus get syncStatus => syncService.status;

  Future<void> load() async {
    _state = await localRepository.loadState();
    notifyListeners();
  }

  void selectClass(String classId) {
    final selectedClass = state.classes.firstWhere(
      (launchClass) => launchClass.id == classId,
      orElse: () => state.launchClass,
    );
    if (selectedClass.id == state.launchClass.id) return;

    _state = LaunchpadState(
      launchClass: selectedClass,
      classes: state.classes,
      warmup: state.warmup,
      teams: state.teams,
      submissions: state.submissions,
      pointEvents: state.pointEvents,
    );
    notifyListeners();
  }

  void startTimer() {
    _timerRunning = true;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining <= 0) {
        _timerRunning = false;
        _ticker?.cancel();
      } else {
        _secondsRemaining--;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void resetTimer() {
    _ticker?.cancel();
    _secondsRemaining = 300;
    _timerRunning = false;
    notifyListeners();
  }

  Future<void> updateWarmup({
    required String prompt,
    required List<String> agenda,
  }) async {
    final updated = state.warmup.copyWith(
      prompt: prompt,
      agenda: agenda.where((item) => item.trim().isNotEmpty).toList(),
      updatedAt: DateTime.now().toUtc(),
    );
    await localRepository.saveWarmup(updated);
    await load();
    await syncService.markPending();
  }

  Future<void> submitAnswer({
    required String teamId,
    required String answer,
    required String confidence,
  }) async {
    final id = _uuid.v4();
    await localRepository.saveSubmission(
      Submission(
        id: id,
        warmupId: state.warmup.id,
        teamId: teamId,
        answer: answer,
        confidence: confidence,
        clientGeneratedId: id,
        submittedAt: DateTime.now().toUtc(),
      ),
    );
    await load();
    await syncService.markPending();
  }

  Future<void> awardPoints({
    required String teamId,
    required String reason,
    int points = 1,
  }) async {
    final id = _uuid.v4();
    await localRepository.savePointEvent(
      PointEvent(
        id: id,
        teamId: teamId,
        warmupId: state.warmup.id,
        reason: reason,
        points: points,
        clientGeneratedId: id,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    await load();
    await syncService.markPending();
  }

  Future<void> updateTeam({
    required String teamId,
    required String name,
    required List<String> members,
  }) async {
    final teams = state.teams.map((team) {
      if (team.id != teamId) return team;
      return team.copyWith(
        name: name,
        members: members,
        updatedAt: DateTime.now().toUtc(),
      );
    }).toList();
    await localRepository.saveTeams(teams);
    await load();
    await syncService.markPending();
  }

  Future<void> resetDemoData() async {
    resetTimer();
    await localRepository.resetDemoData();
    await load();
    await syncService.markPending();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    syncService.removeListener(notifyListeners);
    super.dispose();
  }
}
