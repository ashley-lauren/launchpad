import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../data/local_repository.dart';
import '../models/launchpad_models.dart';
import 'classroom_state_service.dart';
import 'sync_service.dart';
import 'table_layout_randomizer.dart';

class LaunchpadController extends ChangeNotifier {
  LaunchpadController({
    required this.localRepository,
    required this.syncService,
    required this.classroomStateService,
  }) {
    syncService.addListener(notifyListeners);
    unawaited(classroomStateService?.initializePrototypeRow());
    _classroomStateSubscription =
        classroomStateService?.streamClassroomState().listen(
      (state) {
        final previousClassId = _classroomState?.classId;
        _classroomState = state;
        _applyRemoteClassroomState(state);
        if (previousClassId != state.classId) {
          unawaited(loadPersistedLessonsForClass(state.classId));
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _classroomStateReady = false;
        _classroomStateError = true;
        debugPrint('[Launchpad] classroom state error: $error');
        notifyListeners();
      },
    );
  }

  final LocalRepository localRepository;
  final SyncService syncService;
  final ClassroomStateService? classroomStateService;
  final _uuid = const Uuid();

  LaunchpadState? _state;
  Timer? _ticker;
  StreamSubscription<ClassroomState>? _classroomStateSubscription;
  ClassroomState? _classroomState;
  List<LaunchpadClassRecord> _persistedClasses = const [];
  bool _persistedClassesLoading = false;
  String? _persistedClassesError;
  List<LaunchpadLessonRecord> _persistedLessons = const [];
  bool _persistedLessonsLoading = false;
  String? _persistedLessonsError;
  ClassroomState? _latestRemoteClassroomState;
  ClassroomState? _pendingRemoteClassroomState;
  int _secondsRemaining = 300;
  bool _classroomStateReady = false;
  bool _classroomStateError = false;
  bool _followClass = true;
  bool _followClassExplicitlySet = false;

  LaunchpadState get state => _state!;
  int get secondsRemaining => _secondsRemaining;
  bool get timerRunning => _classroomState?.timerStatus == 'running';
  bool get timerPaused => _classroomState?.timerStatus == 'paused';
  String get timerStatus => _classroomState?.timerStatus ?? 'stopped';
  SyncStatus get syncStatus => syncService.status;
  Lesson? get activeLesson => state.activeLesson;
  LessonPhase? get currentPhase => state.currentPhase;
  String get currentActivity => _classroomState?.currentActivity ?? '';
  bool get classroomStateReady => _classroomStateReady;
  bool get classroomStateError => _classroomStateError;
  bool get isLive => _classroomState?.isLive ?? false;
  bool get followClass => _followClass;
  bool get canToggleFollow => isLive;
  ClassroomState? get classroomState => _classroomState;
  List<LaunchpadClassRecord> get persistedClasses => _persistedClasses;
  bool get classesLoading => _persistedClassesLoading;
  String? get classesError => _persistedClassesError;
  List<LaunchpadLessonRecord> get persistedLessons => _persistedLessons;
  bool get lessonsLoading => _persistedLessonsLoading;
  String? get lessonsError => _persistedLessonsError;
  List<LaunchpadStudentRecord> _persistedStudents = const [];
  bool _persistedStudentsLoading = false;
  String? _persistedStudentsError;
  List<LaunchpadTableLayoutRecord> _persistedTableLayouts = const [];
  bool _persistedTableLayoutsLoading = false;
  String? _persistedTableLayoutsError;
  LaunchpadTableLayoutRecord? _activeTableLayout;
  String? _tableLayoutEditorName;
  int _tableLayoutEditorTableCount = 6;
  bool _tableLayoutEditorDirty = false;
  int? _tableLayoutEditorSelectionId;
  Map<int, int> _tableLayoutEditorAssignments = const {};
  RandomizationOptions _tableLayoutEditorRandomizationOptions =
      const RandomizationOptions(
    balanceTableSizes: true,
    preferNewTablemates: true,
    avoidRecentTablemates: 2,
  );
  String _tableLayoutEditorConstraintsText = '';
  Map<int, int>? _tableLayoutEditorAssignmentsBeforeRandomize;
  String? _tableLayoutEditorRandomizationSummary;
  List<LaunchpadStudentRecord> get persistedStudents => _persistedStudents;
  bool get studentsLoading => _persistedStudentsLoading;
  String? get studentsError => _persistedStudentsError;
  List<LaunchpadTableLayoutRecord> get persistedTableLayouts => _persistedTableLayouts;
  bool get tableLayoutsLoading => _persistedTableLayoutsLoading;
  String? get tableLayoutsError => _persistedTableLayoutsError;
  LaunchpadTableLayoutRecord? get activeTableLayout => _activeTableLayout;
  String? get tableLayoutEditorName => _tableLayoutEditorName;
  int get tableLayoutEditorTableCount => _tableLayoutEditorTableCount;
  bool get tableLayoutEditorDirty => _tableLayoutEditorDirty;
  int? get tableLayoutEditorSelectionId => _tableLayoutEditorSelectionId;
  Map<int, int> get tableLayoutEditorAssignments => _tableLayoutEditorAssignments;
  RandomizationOptions get tableLayoutEditorRandomizationOptions =>
      _tableLayoutEditorRandomizationOptions;
  String get tableLayoutEditorConstraintsText => _tableLayoutEditorConstraintsText;
  String? get tableLayoutEditorRandomizationSummary =>
      _tableLayoutEditorRandomizationSummary;
  LaunchpadClassRecord? get selectedPersistedClass {
    final classId = _classroomState?.classId;
    if (classId == null) return null;
    for (final item in _persistedClasses) {
      if (item.id == classId) return item;
    }
    return null;
  }

  LaunchpadLessonRecord? get selectedPersistedLesson {
    final lessonId = _classroomState?.lessonId;
    if (lessonId == null) return null;
    for (final item in _persistedLessons) {
      if (item.id == lessonId) return item;
    }
    return null;
  }

  String get liveStatusLabel =>
      !isLive ? 'Not Live' : (_followClass ? 'Following Class' : 'Independent');
  Color get liveStatusColor => !isLive
      ? const Color(0xFF8B949E)
      : (_followClass ? const Color(0xFF7EE787) : const Color(0xFFFFC857));
  String get classroomStateStatusText => _classroomStateError
      ? 'Realtime unavailable'
      : _classroomStateReady
          ? 'Realtime connected'
          : 'Connecting to classroom state...';

  Future<void> load() async {
    _state = await localRepository.loadState();
    _secondsRemaining = _durationForCurrentPhase();
    if (_classroomState != null) {
      _applyRemoteClassroomState(_classroomState!, notify: false);
    } else if (_pendingRemoteClassroomState != null) {
      _applyRemoteClassroomState(_pendingRemoteClassroomState!, notify: false);
      _pendingRemoteClassroomState = null;
    }
    await loadPersistedClasses();
    await loadPersistedLessonsForCurrentClass();
    await loadPersistedStudentsForCurrentClass();
    await loadPersistedTableLayoutsForCurrentClass();
    _syncTableLayoutEditorFromClassroomState();
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

  Future<void> startTimer() async {
    if (classroomStateService == null) {
      _classroomStateError = true;
      notifyListeners();
      return;
    }
    final duration = _timerDurationSeconds();
    debugPrint('[Launchpad] Start timer clicked: ${duration}s');
    try {
      debugPrint('[Launchpad] timer start -> $duration');
      await classroomStateService!.startTimer(durationSeconds: duration);
      _classroomState = (_classroomState ?? const ClassroomState()).copyWith(
        timerStatus: 'running',
        timerDurationSeconds: duration,
        timerRemainingSeconds: duration,
        timerEndsAt: DateTime.now().toUtc().add(Duration(seconds: duration)),
      );
      _secondsRemaining = duration;
      _classroomStateReady = true;
      _classroomStateError = false;
      _syncTimerFromState();
      notifyListeners();
    } catch (error) {
      _classroomStateError = true;
      debugPrint('[Launchpad] startTimer failed: $error');
      notifyListeners();
    }
  }

  Future<void> pauseTimer() async {
    if (classroomStateService == null) {
      _classroomStateError = true;
      notifyListeners();
      return;
    }
    final remaining = _secondsRemaining.clamp(0, 86400);
    debugPrint('[Launchpad] Pause timer clicked: ${remaining}s');
    try {
      debugPrint('[Launchpad] timer pause -> $remaining');
      await classroomStateService!.pauseTimer(remainingSeconds: remaining);
      _classroomState = (_classroomState ?? const ClassroomState()).copyWith(
        timerStatus: 'paused',
        timerRemainingSeconds: remaining,
        timerEndsAt: null,
      );
      _secondsRemaining = remaining;
      _classroomStateReady = true;
      _classroomStateError = false;
      _syncTimerFromState();
      notifyListeners();
    } catch (error) {
      _classroomStateError = true;
      debugPrint('[Launchpad] pauseTimer failed: $error');
      notifyListeners();
    }
  }

  Future<void> resumeTimer() async {
    if (classroomStateService == null) {
      _classroomStateError = true;
      notifyListeners();
      return;
    }
    final remaining = _secondsRemaining.clamp(0, 86400);
    debugPrint('[Launchpad] Resume timer clicked: ${remaining}s');
    try {
      debugPrint('[Launchpad] timer resume -> $remaining');
      await classroomStateService!.resumeTimer(remainingSeconds: remaining);
      _classroomState = (_classroomState ?? const ClassroomState()).copyWith(
        timerStatus: 'running',
        timerRemainingSeconds: remaining,
        timerEndsAt: DateTime.now().toUtc().add(Duration(seconds: remaining)),
      );
      _secondsRemaining = remaining;
      _classroomStateReady = true;
      _classroomStateError = false;
      _syncTimerFromState();
      notifyListeners();
    } catch (error) {
      _classroomStateError = true;
      debugPrint('[Launchpad] resumeTimer failed: $error');
      notifyListeners();
    }
  }

  Future<void> resetTimer() async {
    if (classroomStateService == null) {
      _classroomStateError = true;
      notifyListeners();
      return;
    }
    final duration = _timerDurationSeconds();
    debugPrint('[Launchpad] Reset timer clicked: ${duration}s');
    try {
      debugPrint('[Launchpad] timer reset -> $duration');
      await classroomStateService!.resetTimer(durationSeconds: duration);
      _classroomState = (_classroomState ?? const ClassroomState()).copyWith(
        timerStatus: 'stopped',
        timerDurationSeconds: duration,
        timerRemainingSeconds: duration,
        timerEndsAt: null,
      );
      _secondsRemaining = duration;
      _classroomStateReady = true;
      _classroomStateError = false;
      _syncTimerFromState();
      notifyListeners();
    } catch (error) {
      _classroomStateError = true;
      debugPrint('[Launchpad] resetTimer failed: $error');
      notifyListeners();
    }
  }

  Future<void> startLiveClass() async {
    if (classroomStateService == null) {
      _classroomStateError = true;
      notifyListeners();
      return;
    }
    try {
      debugPrint('[Live] is_live -> true');
      await classroomStateService!.startLiveClass();
      _classroomState = (_classroomState ?? const ClassroomState()).copyWith(
        isLive: true,
      );
      _followClass = true;
      _followClassExplicitlySet = false;
      _classroomStateReady = true;
      _classroomStateError = false;
      if (_latestRemoteClassroomState != null) {
        _applyRemoteClassroomState(_latestRemoteClassroomState!,
            notify: false, forceApply: true);
      }
      notifyListeners();
    } catch (error) {
      _classroomStateError = true;
      debugPrint('[Launchpad] startLiveClass failed: $error');
      notifyListeners();
    }
  }

  Future<void> endLiveClass() async {
    if (classroomStateService == null) {
      _classroomStateError = true;
      notifyListeners();
      return;
    }
    try {
      debugPrint('[Live] is_live -> false');
      await classroomStateService!.endLiveClass();
      _classroomState = (_classroomState ?? const ClassroomState()).copyWith(
        isLive: false,
      );
      _followClass = false;
      _followClassExplicitlySet = false;
      _classroomStateReady = true;
      _classroomStateError = false;
      notifyListeners();
    } catch (error) {
      _classroomStateError = true;
      debugPrint('[Launchpad] endLiveClass failed: $error');
      notifyListeners();
    }
  }

  void toggleFollowClass() {
    if (!isLive) return;
    _followClass = !_followClass;
    _followClassExplicitlySet = true;
    if (_followClass && _latestRemoteClassroomState != null) {
      debugPrint(
          '[Follow] rejoined class -> ${_latestRemoteClassroomState!.currentPhaseId ?? 'none'}');
      _applyRemoteClassroomState(_latestRemoteClassroomState!,
          notify: false, forceApply: true);
    } else {
      debugPrint('[Follow] followClass -> $_followClass');
    }
    notifyListeners();
  }

  Future<void> importLessonJson(String rawJson) async {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Lesson JSON must be an object.');
    }
    final lesson = Lesson.fromJson(decoded);
    if (lesson.phases.isEmpty) {
      throw const FormatException(
          'Lesson JSON must include at least one phase.');
    }
    _ticker?.cancel();
    _ticker = null;
    await localRepository.saveLessonState(
      lesson: lesson,
      currentPhaseIndex: 0,
    );
    await load();
    _secondsRemaining = _durationForCurrentPhase();
    notifyListeners();
  }

  Future<void> goToPhase(int phaseIndex) async {
    final lesson = state.activeLesson;
    if (lesson == null || lesson.phases.isEmpty) return;
    final nextIndex = phaseIndex.clamp(0, lesson.phases.length - 1);
    _ticker?.cancel();
    _ticker = null;
    _state = state.copyWith(currentPhaseIndex: nextIndex);
    await localRepository.saveCurrentPhaseIndex(nextIndex);

    final selectedPhase = _state!.currentPhase;
    final activityName = _activityLabelForPhase(selectedPhase);
    debugPrint('[Launchpad] nextPhase clicked');
    debugPrint('[Launchpad] local phase -> ${selectedPhase?.id ?? 'none'}');
    debugPrint('[Launchpad] section changed to: $activityName');
    if (selectedPhase != null && activityName.isNotEmpty) {
      _classroomState = (_classroomState ?? const ClassroomState()).copyWith(
        currentPhaseId: selectedPhase.id,
        currentActivity: activityName,
      );
      debugPrint('[Supabase] publishing phase -> ${selectedPhase.id}');
      await classroomStateService?.updateCurrentPhase(
        phaseId: selectedPhase.id,
        activityTitle: activityName,
      );
      debugPrint('[Supabase] updated row -> ${selectedPhase.id}');
    } else if (activityName.isNotEmpty) {
      await updateCurrentActivity(activityName);
    }
    _secondsRemaining = _durationForCurrentPhase();
    notifyListeners();
  }

  Future<void> nextPhase() => goToPhase(state.currentPhaseIndex + 1);

  Future<void> previousPhase() => goToPhase(state.currentPhaseIndex - 1);

  Future<void> restartPhaseTimer() => resetTimer();

  String _activityLabelForPhase(LessonPhase? phase) {
    if (phase == null) {
      return state.warmup.prompt.trim();
    }
    if (phase.title.trim().isNotEmpty) {
      return phase.title.trim();
    }
    if (phase.prompt.trim().isNotEmpty) {
      return phase.prompt.trim();
    }
    return phase.title.trim();
  }

  Future<void> loadPersistedClasses() async {
    if (classroomStateService == null) {
      _persistedClasses = const [];
      _persistedClassesLoading = false;
      _persistedClassesError = 'Supabase unavailable';
      notifyListeners();
      return;
    }

    _persistedClassesLoading = true;
    _persistedClassesError = null;
    notifyListeners();

    try {
      final classes = await classroomStateService!.fetchClasses();
      _persistedClasses = classes;
      _persistedClassesLoading = false;
      _persistedClassesError = null;
      notifyListeners();
    } catch (error) {
      _persistedClasses = const [];
      _persistedClassesLoading = false;
      _persistedClassesError = error.toString();
      debugPrint('[Launchpad] loadPersistedClasses failed: $error');
      notifyListeners();
    }
  }

  Future<List<LaunchpadClassRecord>> fetchSupabaseClasses() async {
    await loadPersistedClasses();
    return _persistedClasses;
  }

  Future<void> loadPersistedLessonsForCurrentClass() async {
    await loadPersistedLessonsForClass(_classroomState?.classId);
  }

  Future<void> loadPersistedLessonsForClass(int? classId) async {
    if (classroomStateService == null || classId == null) {
      _persistedLessons = const [];
      _persistedLessonsLoading = false;
      _persistedLessonsError = 'No class selected';
      notifyListeners();
      return;
    }

    _persistedLessonsLoading = true;
    _persistedLessonsError = null;
    notifyListeners();

    try {
      final lessons = await classroomStateService!.fetchLessonsForClass(classId);
      _persistedLessons = lessons;
      _persistedLessonsLoading = false;
      _persistedLessonsError = null;
      notifyListeners();
    } catch (error) {
      _persistedLessons = const [];
      _persistedLessonsLoading = false;
      _persistedLessonsError = error.toString();
      debugPrint('[Launchpad] loadPersistedLessonsForClass failed: $error');
      notifyListeners();
    }
  }

  Future<void> updateSelectedClass(int classId) async {
    if (classroomStateService == null) {
      _classroomStateError = true;
      notifyListeners();
      return;
    }
    try {
      await classroomStateService!.updateSelectedClass(classId);
      _classroomState = (_classroomState ?? const ClassroomState()).copyWith(
        classId: classId,
        lessonId: null,
        tableLayoutId: null,
      );
      _classroomStateReady = true;
      _classroomStateError = false;
      await loadPersistedLessonsForClass(classId);
      await loadPersistedStudentsForClass(classId);
      await loadPersistedTableLayoutsForClass(classId);
      _resetTableLayoutEditor();
      notifyListeners();
    } catch (error) {
      _classroomStateError = true;
      debugPrint('[Launchpad] updateSelectedClass failed: $error');
      notifyListeners();
    }
  }

  Future<void> loadPersistedStudentsForCurrentClass() async {
    final classId = _classroomState?.classId;
    if (classId == null) {
      _persistedStudents = const [];
      _persistedStudentsLoading = false;
      _persistedStudentsError = null;
      return;
    }
    await loadPersistedStudentsForClass(classId);
  }

  Future<void> loadPersistedStudentsForClass(int? classId) async {
    if (classroomStateService == null || classId == null) {
      _persistedStudents = const [];
      _persistedStudentsLoading = false;
      _persistedStudentsError = 'No class selected';
      notifyListeners();
      return;
    }

    _persistedStudentsLoading = true;
    _persistedStudentsError = null;
    notifyListeners();

    try {
      final students = await classroomStateService!.fetchStudentsForClass(classId);
      _persistedStudents = students;
      _persistedStudentsLoading = false;
      _persistedStudentsError = null;
      notifyListeners();
    } catch (error) {
      _persistedStudents = const [];
      _persistedStudentsLoading = false;
      _persistedStudentsError = error.toString();
      debugPrint('[Launchpad] loadPersistedStudentsForClass failed: $error');
      notifyListeners();
    }
  }

  Future<void> loadPersistedTableLayoutsForCurrentClass() async {
    final classId = _classroomState?.classId;
    if (classId == null) {
      _persistedTableLayouts = const [];
      _persistedTableLayoutsLoading = false;
      _persistedTableLayoutsError = null;
      return;
    }
    await loadPersistedTableLayoutsForClass(classId);
  }

  Future<void> loadPersistedTableLayoutsForClass(int? classId) async {
    if (classroomStateService == null || classId == null) {
      _persistedTableLayouts = const [];
      _persistedTableLayoutsLoading = false;
      _persistedTableLayoutsError = 'No class selected';
      notifyListeners();
      return;
    }

    _persistedTableLayoutsLoading = true;
    _persistedTableLayoutsError = null;
    notifyListeners();

    try {
      final layouts = await classroomStateService!.fetchTableLayoutsForClass(classId);
      _persistedTableLayouts = layouts;
      _persistedTableLayoutsLoading = false;
      _persistedTableLayoutsError = null;
      _activeTableLayout = layouts.cast<LaunchpadTableLayoutRecord?>().firstWhere(
        (layout) => layout?.id == _classroomState?.tableLayoutId,
        orElse: () => null,
      );
      notifyListeners();
    } catch (error) {
      _persistedTableLayouts = const [];
      _persistedTableLayoutsLoading = false;
      _persistedTableLayoutsError = error.toString();
      debugPrint('[Launchpad] loadPersistedTableLayoutsForClass failed: $error');
      notifyListeners();
    }
  }

  void startNewTableLayoutEditor({String? name, int? tableCount}) {
    _tableLayoutEditorName = name ?? '';
    _tableLayoutEditorTableCount = tableCount?.clamp(1, 12) ?? 6;
    _tableLayoutEditorSelectionId = null;
    _tableLayoutEditorAssignments = const {};
    _tableLayoutEditorAssignmentsBeforeRandomize = null;
    _tableLayoutEditorRandomizationSummary = null;
    _tableLayoutEditorDirty = false;
    notifyListeners();
  }

  Future<void> selectTableLayoutEditor(int? layoutId) async {
    _tableLayoutEditorSelectionId = layoutId;
    if (layoutId == null) {
      _tableLayoutEditorName = '';
      _tableLayoutEditorTableCount = 6;
      _tableLayoutEditorAssignments = const {};
      _tableLayoutEditorDirty = false;
      notifyListeners();
      return;
    }

    final layout = _persistedTableLayouts.firstWhere(
      (item) => item.id == layoutId,
      orElse: () => const LaunchpadTableLayoutRecord(
        id: 0,
        classId: 0,
        name: '',
        tableCount: 6,
      ),
    );
    _tableLayoutEditorName = layout.name;
    _tableLayoutEditorTableCount = layout.tableCount.clamp(1, 12);
    _tableLayoutEditorAssignments = const {};
    _tableLayoutEditorDirty = false;
    if (classroomStateService != null) {
      await classroomStateService!.setActiveTableLayout(layoutId: layoutId);
    }
    _classroomState = (_classroomState ?? const ClassroomState()).copyWith(
      tableLayoutId: layoutId,
    );
    await loadTableLayoutEditorAssignments(layoutId);
    notifyListeners();
  }

  Future<void> loadTableLayoutEditorAssignments(int layoutId) async {
    if (classroomStateService == null) return;
    final members = await classroomStateService!.fetchTableLayoutMembers(layoutId);
    final assignments = <int, int>{};
    for (final member in members) {
      assignments[member.studentId] = member.tableNumber;
    }
    _tableLayoutEditorAssignments = assignments;
    _tableLayoutEditorDirty = false;
    notifyListeners();
  }

  void assignStudentToTable({required int studentId, required int tableNumber}) {
    final next = <int, int>{..._tableLayoutEditorAssignments};
    next.remove(studentId);
    next[studentId] = tableNumber;
    _tableLayoutEditorAssignments = next;
    _tableLayoutEditorDirty = true;
    notifyListeners();
  }

  void removeStudentFromLayout(int studentId) {
    final next = <int, int>{..._tableLayoutEditorAssignments};
    next.remove(studentId);
    _tableLayoutEditorAssignments = next;
    _tableLayoutEditorDirty = true;
    notifyListeners();
  }

  void moveStudentToTable({required int studentId, required int? tableNumber}) {
    if (tableNumber == null || tableNumber == 0) {
      removeStudentFromLayout(studentId);
      return;
    }
    assignStudentToTable(studentId: studentId, tableNumber: tableNumber);
  }

  void updateTableLayoutEditorName(String value) {
    _tableLayoutEditorName = value;
    notifyListeners();
  }

  void updateTableLayoutEditorTableCount(int value) {
    _tableLayoutEditorTableCount = value.clamp(1, 12);
    notifyListeners();
  }

  void updateTableLayoutEditorRandomizationOptions({
    bool? balanceTableSizes,
    bool? preferNewTablemates,
    int? avoidRecentTablemates,
  }) {
    _tableLayoutEditorRandomizationOptions = RandomizationOptions(
      balanceTableSizes: balanceTableSizes ??
          _tableLayoutEditorRandomizationOptions.balanceTableSizes,
      preferNewTablemates: preferNewTablemates ??
          _tableLayoutEditorRandomizationOptions.preferNewTablemates,
      avoidRecentTablemates: avoidRecentTablemates ??
          _tableLayoutEditorRandomizationOptions.avoidRecentTablemates,
    );
    notifyListeners();
  }

  void updateTableLayoutEditorConstraintsText(String value) {
    _tableLayoutEditorConstraintsText = value;
    notifyListeners();
  }

  Future<void> randomizeTableLayoutEditor() async {
    if (classroomStateService == null) {
      throw StateError('Classroom state service is unavailable.');
    }
    if (_persistedStudents.isEmpty) {
      throw StateError('No students are loaded for this class.');
    }

    final validation = TableLayoutRandomizer.parseConstraints(
      rawText: _tableLayoutEditorConstraintsText,
      students: _persistedStudents,
      tableCount: _tableLayoutEditorTableCount,
    );
    if (validation.errors.isNotEmpty) {
      throw StateError(validation.errors.join('\n'));
    }

    final historyLayouts = <LaunchpadTableLayoutRecord>[];
    for (final layout in _persistedTableLayouts) {
      if (layout.classId != _classroomState?.classId) {
        continue;
      }
      if (_tableLayoutEditorSelectionId != null && layout.id == _tableLayoutEditorSelectionId) {
        continue;
      }
      historyLayouts.add(layout);
    }
    historyLayouts.sort((a, b) => b.id.compareTo(a.id));

    final historyMembers = <int, List<LaunchpadTableLayoutMember>>{};
    for (final layout in historyLayouts.take(
      _tableLayoutEditorRandomizationOptions.avoidRecentTablemates,
    )) {
      historyMembers[layout.id] = await classroomStateService!.fetchTableLayoutMembers(layout.id);
    }

    final result = TableLayoutRandomizer.randomize(
      students: _persistedStudents,
      tableCount: _tableLayoutEditorTableCount,
      options: _tableLayoutEditorRandomizationOptions,
      constraints: validation.constraints,
      history: historyLayouts,
      layoutMembersByLayoutId: historyMembers,
    );

    _tableLayoutEditorAssignmentsBeforeRandomize =
        Map<int, int>.from(_tableLayoutEditorAssignments);
    _tableLayoutEditorAssignments = result.assignments;
    _tableLayoutEditorDirty = true;
    _tableLayoutEditorRandomizationSummary = result.summary;
    notifyListeners();
  }

  void undoTableLayoutEditorRandomize() {
    if (_tableLayoutEditorAssignmentsBeforeRandomize == null) {
      return;
    }
    _tableLayoutEditorAssignments =
        Map<int, int>.from(_tableLayoutEditorAssignmentsBeforeRandomize!);
    _tableLayoutEditorAssignmentsBeforeRandomize = null;
    _tableLayoutEditorDirty = true;
    _tableLayoutEditorRandomizationSummary = null;
    notifyListeners();
  }

  Future<void> saveTableLayoutEditor() async {
    if (classroomStateService == null) return;
    final classId = _classroomState?.classId;
    if (classId == null) {
      throw StateError('Select a class before saving a table layout.');
    }
    final name = (_tableLayoutEditorName ?? '').trim();
    if (name.isEmpty) {
      throw StateError('Enter a layout name.');
    }

    final layout = _tableLayoutEditorSelectionId == null
        ? await classroomStateService!.createTableLayout(
            classId: classId,
            name: name,
            tableCount: _tableLayoutEditorTableCount,
          )
        : await _updateExistingTableLayout(
            layoutId: _tableLayoutEditorSelectionId!,
            name: name,
            tableCount: _tableLayoutEditorTableCount,
          );

    final members = _tableLayoutEditorAssignments.entries
        .map((entry) => LaunchpadTableLayoutMember(
              studentId: entry.key,
              tableNumber: entry.value,
            ))
        .toList();
    await classroomStateService!.saveTableLayoutAssignments(
      layoutId: layout.id,
      members: members,
    );
    await classroomStateService!.setActiveTableLayout(layoutId: layout.id);
    _classroomState = (_classroomState ?? const ClassroomState()).copyWith(
      classId: classId,
      tableLayoutId: layout.id,
    );
    _tableLayoutEditorSelectionId = layout.id;
    _tableLayoutEditorDirty = false;
    _activeTableLayout = layout;
    await loadPersistedTableLayoutsForClass(classId);
    notifyListeners();
  }

  Future<LaunchpadTableLayoutRecord> _updateExistingTableLayout({
    required int layoutId,
    required String name,
    required int tableCount,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final response = await Supabase.instance.client
        .from('table_layouts')
        .update({
          'name': name.trim(),
          'table_count': tableCount,
          'updated_at': now,
        })
        .eq('id', layoutId)
        .select()
        .single();
    return LaunchpadTableLayoutRecord.fromJson(response);
  }

  void _resetTableLayoutEditor() {
    _tableLayoutEditorName = '';
    _tableLayoutEditorTableCount = 6;
    _tableLayoutEditorSelectionId = null;
    _tableLayoutEditorAssignments = const {};
    _tableLayoutEditorAssignmentsBeforeRandomize = null;
    _tableLayoutEditorRandomizationSummary = null;
    _tableLayoutEditorDirty = false;
    _activeTableLayout = null;
  }

  void _syncTableLayoutEditorFromClassroomState() {
    if (_classroomState?.tableLayoutId == null) {
      _activeTableLayout = null;
      return;
    }
    _activeTableLayout = _persistedTableLayouts.cast<LaunchpadTableLayoutRecord?>().firstWhere(
      (layout) => layout?.id == _classroomState!.tableLayoutId,
      orElse: () => null,
    );
  }

  Future<void> updateSelectedLesson(int lessonId) async {
    if (classroomStateService == null) {
      _classroomStateError = true;
      notifyListeners();
      return;
    }
    try {
      await classroomStateService!.updateSelectedLesson(lessonId);
      _classroomState = (_classroomState ?? const ClassroomState()).copyWith(
        lessonId: lessonId,
        currentPhaseId: null,
        currentActivity: '',
      );
      _classroomStateReady = true;
      _classroomStateError = false;
      notifyListeners();
    } catch (error) {
      _classroomStateError = true;
      debugPrint('[Launchpad] updateSelectedLesson failed: $error');
      notifyListeners();
    }
  }

  Future<LaunchpadLessonRecord> createLesson({
    required int classId,
    required DateTime lessonDate,
    required String title,
  }) async {
    if (classroomStateService == null) {
      _classroomStateError = true;
      notifyListeners();
      throw StateError('Classroom state service is unavailable.');
    }
    try {
      final lesson = await classroomStateService!.createLesson(
        classId: classId,
        lessonDate: lessonDate,
        title: title,
      );
      await loadPersistedLessonsForClass(classId);
      _classroomState = (_classroomState ?? const ClassroomState()).copyWith(
        classId: classId,
        lessonId: lesson.id,
        currentPhaseId: null,
        currentActivity: '',
      );
      await classroomStateService!.updateSelectedLesson(lesson.id);
      _classroomStateReady = true;
      _classroomStateError = false;
      notifyListeners();
      return lesson;
    } catch (error) {
      _classroomStateError = true;
      debugPrint('[Launchpad] createLesson failed: $error');
      notifyListeners();
      rethrow;
    }
  }

  Future<Lesson> loadLessonEditorContent({required int lessonId}) async {
    if (classroomStateService == null) {
      throw StateError('Classroom state service is unavailable.');
    }

    final rawLessonJson = await classroomStateService!.fetchLessonDocument(lessonId);
    if (rawLessonJson != null) {
      return Lesson.fromJson(Map<String, dynamic>.from(rawLessonJson));
    }

    final metadata = _persistedLessons.firstWhere(
      (item) => item.id == lessonId,
      orElse: () => const LaunchpadLessonRecord(
        id: 0,
        classId: 0,
        lessonDate: null,
        title: '',
      ),
    );
    final phaseRows = await classroomStateService!.fetchLessonPhases(lessonId);
    final lessonJson = {
      'lessonInfo': {
        'title': metadata.title,
        'course': '',
        'period': '',
        'date': metadata.lessonDate?.toIso8601String() ?? '',
      },
      'displaySettings': {
        'showAgenda': true,
        'showClock': true,
        'showTeamMap': true,
        'showLeaderboard': false,
      },
      'standards': <Map<String, dynamic>>[],
      'learningObjectives': <String>[],
      'successCriteria': <String>[],
      'vocabulary': <String>[],
      'materials': <String>[],
      'differentiation': <String, dynamic>{},
      'teacherMoves': <String, dynamic>{},
      'pointRewards': <Map<String, dynamic>>[],
      'phases': phaseRows
          .map((row) => {
                'id': row['phase_key'],
                'type': row['phase_type'] ?? 'discussion',
                'title': row['title'] ?? 'Untitled Phase',
                'durationSeconds': row['duration_seconds'] ?? 300,
                'prompt': row['prompt'] ?? '',
                'instructions': row['instructions'] ?? <String>[],
                'submission': {
                  'enabled': false,
                  'mode': row['submission_mode'] ?? 'individual',
                  'confidenceSelector': false,
                },
                'teacherNotes': <String>[],
                'display': <String, dynamic>{},
                'discussionPrompts': <String>[],
                'reflectionQuestions': <String>[],
                'keyIdeas': <String>[],
                'keyActions': <String>[],
              })
          .toList(),
    };
    return Lesson.fromJson(lessonJson);
  }

  Future<void> saveLessonEditorJson({
    required int lessonId,
    required int classId,
    required DateTime lessonDate,
    required String title,
    required Lesson lesson,
  }) async {
    if (classroomStateService == null) {
      throw StateError('Classroom state service is unavailable.');
    }
    await classroomStateService!.saveLessonDocument(
      lessonId: lessonId,
      classId: classId,
      lessonDate: lessonDate,
      title: title,
      lessonJson: lesson.toJson(),
      phases: lesson.phases,
    );
    await loadPersistedLessonsForClass(classId);
    _classroomState = (_classroomState ?? const ClassroomState()).copyWith(
      classId: classId,
      lessonId: lessonId,
      currentPhaseId: null,
      currentActivity: '',
    );
    await classroomStateService!.updateSelectedLesson(lessonId);
    notifyListeners();
  }

  Future<void> updateCurrentActivity(String activity) async {
    final trimmed = activity.trim();
    if (classroomStateService == null) {
      _classroomStateError = true;
      notifyListeners();
      return;
    }
    debugPrint('[Launchpad] publishing activity: $trimmed');
    try {
      await classroomStateService!.updateCurrentActivity(trimmed);
      _classroomState = (_classroomState ?? const ClassroomState()).copyWith(
        currentActivity: trimmed,
      );
      _classroomStateReady = true;
      _classroomStateError = false;
      debugPrint('[Launchpad] activity updated to $trimmed');
      notifyListeners();
    } catch (error) {
      _classroomStateError = true;
      debugPrint('[Launchpad] activity update failed: $error');
      notifyListeners();
    }
  }

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
    List<String>? contributors,
  }) async {
    final id = _uuid.v4();
    await localRepository.saveSubmission(
      Submission(
        id: id,
        warmupId: state.currentPhase?.id ?? state.warmup.id,
        teamId: teamId,
        answer: answer,
        confidence: confidence,
        contributors: contributors ?? const [],
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
    await resetTimer();
    await localRepository.resetDemoData();
    await load();
    await syncService.markPending();
  }

  int _timerDurationSeconds() {
    final duration = state.currentPhase?.durationSeconds;
    if (duration != null && duration > 0) return duration;
    return 300;
  }

  void _applyRemoteClassroomState(
    ClassroomState state, {
    bool notify = true,
    bool forceApply = false,
  }) {
    _latestRemoteClassroomState = state;
    _classroomStateReady = true;
    _classroomStateError = false;

    if (!state.isLive) {
      _followClass = false;
      _followClassExplicitlySet = false;
      _classroomState = (_classroomState ?? const ClassroomState()).copyWith(
        isLive: false,
      );
      _syncTimerFromState();
      if (notify) {
        notifyListeners();
      }
      return;
    }

    if (!_followClassExplicitlySet) {
      _followClass = true;
    }

    if (_followClass || forceApply) {
      debugPrint('[Live] is_live -> true');
      debugPrint('[Follow] followClass -> $_followClass');
      _classroomState = state;
      if (_state != null) {
        final phaseId = state.currentPhaseId;
        if (phaseId != null && phaseId.isNotEmpty) {
          final remoteIndex = _state!.phaseIndexForId(phaseId);
          if (remoteIndex != null && remoteIndex != _state!.currentPhaseIndex) {
            _state = _state!.copyWith(currentPhaseIndex: remoteIndex);
            debugPrint('[Realtime] phase received -> $phaseId');
            debugPrint('[Follow] remote phase applied -> $phaseId');
            debugPrint(
                '[Launchpad] remote phase applied -> index $remoteIndex');
          } else if (forceApply && remoteIndex != null) {
            debugPrint('[Follow] rejoined class -> $phaseId');
          }
        }
      } else {
        _pendingRemoteClassroomState = state;
      }
      _syncTimerFromState();
    } else {
      debugPrint(
          '[Follow] remote phase ignored while independent -> ${state.currentPhaseId ?? 'none'}');
      _classroomState = (_classroomState ?? const ClassroomState()).copyWith(
        isLive: true,
        currentActivity: state.currentActivity,
      );
    }

    if (notify) {
      notifyListeners();
    }
  }

  void _syncTimerFromState() {
    final state = _classroomState;
    if (state == null) return;
    switch (state.timerStatus) {
      case 'running':
        if (state.timerEndsAt != null) {
          final remaining =
              state.timerEndsAt!.difference(DateTime.now().toUtc()).inSeconds;
          _secondsRemaining = remaining < 0 ? 0 : remaining;
          _startLocalTicker();
        } else {
          _secondsRemaining = state.timerRemainingSeconds;
          _stopLocalTicker();
        }
        break;
      case 'paused':
        _secondsRemaining = state.timerRemainingSeconds;
        _stopLocalTicker();
        break;
      default:
        _secondsRemaining = state.timerRemainingSeconds;
        _stopLocalTicker();
        break;
    }
  }

  void _startLocalTicker() {
    if (_ticker != null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final state = _classroomState;
      if (state == null ||
          state.timerStatus != 'running' ||
          state.timerEndsAt == null) {
        _stopLocalTicker();
        return;
      }
      final remaining =
          state.timerEndsAt!.difference(DateTime.now().toUtc()).inSeconds;
      _secondsRemaining = remaining < 0 ? 0 : remaining;
      if (_secondsRemaining <= 0) {
        _stopLocalTicker();
      }
      notifyListeners();
    });
  }

  void _stopLocalTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  int _durationForCurrentPhase() {
    return _timerDurationSeconds();
  }

  @override
  void dispose() {
    _stopLocalTicker();
    _classroomStateSubscription?.cancel();
    syncService.removeListener(notifyListeners);
    super.dispose();
  }
}
