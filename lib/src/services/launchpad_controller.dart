import 'dart:async';
import 'dart:convert';

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
  Lesson? get activeLesson => state.activeLesson;
  LessonPhase? get currentPhase => state.currentPhase;

  Future<void> load() async {
    _state = await localRepository.loadState();
    _secondsRemaining = _durationForCurrentPhase();
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
      activeLesson: state.activeLesson,
      currentPhaseIndex: state.currentPhaseIndex,
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

  void pauseTimer() {
    _timerRunning = false;
    _ticker?.cancel();
    notifyListeners();
  }

  void resetTimer() {
    _ticker?.cancel();
    _secondsRemaining = _durationForCurrentPhase();
    _timerRunning = false;
    notifyListeners();
  }

  Future<void> importLessonJson(String rawJson) async {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Lesson JSON must be an object.');
    }
    final lesson = Lesson.fromJson(decoded);
    if (lesson.phases.isEmpty) {
      throw const FormatException('Lesson JSON must include at least one phase.');
    }
    _ticker?.cancel();
    await localRepository.saveLessonState(
      lesson: lesson,
      currentPhaseIndex: 0,
    );
    await load();
    _secondsRemaining = _durationForCurrentPhase();
    _timerRunning = false;
    notifyListeners();
  }

  Future<void> goToPhase(int phaseIndex) async {
    final lesson = state.activeLesson;
    if (lesson == null || lesson.phases.isEmpty) return;
    final nextIndex = phaseIndex.clamp(0, lesson.phases.length - 1);
    _ticker?.cancel();
    await localRepository.saveCurrentPhaseIndex(nextIndex);
    await load();
    _secondsRemaining = _durationForCurrentPhase();
    _timerRunning = false;
    notifyListeners();
  }

  Future<void> nextPhase() => goToPhase(state.currentPhaseIndex + 1);

  Future<void> previousPhase() => goToPhase(state.currentPhaseIndex - 1);

  void restartPhaseTimer() => resetTimer();

  Future<void> updateWarmup({
    required String prompt,
    required List<String> agenda,
  }) async {
    final agendaItems =
        agenda.where((item) => item.trim().isNotEmpty).map((item) {
      final trimmed = item.trim();
      return AgendaItem(
        title: trimmed,
        durationMinutes: 5,
      );
    }).toList();

    final updated = state.warmup.copyWith(
      prompt: prompt,
      agenda: agendaItems,
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
        warmupId: state.currentPhase?.id ?? state.warmup.id,
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

  int _durationForCurrentPhase() {
    final duration = state.currentPhase?.durationSeconds;
    if (duration != null && duration > 0) return duration;
    return 300;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    syncService.removeListener(notifyListeners);
    super.dispose();
  }
}
