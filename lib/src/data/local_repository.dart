import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/launchpad_models.dart';
import 'launchpad_repository.dart';

class LocalRepository implements LaunchpadRepository {
  LocalRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _stateKey = 'launchpad.local.state.v1';

  Future<void> ensureSeeded() async {
    if (_prefs.containsKey(_stateKey)) return;
    await resetDemoData();
  }

  Future<void> resetDemoData() async {
    final now = DateTime.now().toUtc();
    const classId = '00000000-0000-4000-8000-000000000001';
    const warmupId = '00000000-0000-4000-8000-000000000101';
    final accentColors = const [
      '#E91E63',
      '#FF5722',
      '#FF9800',
      '#69F0AE',
      '#2196F3',
      '#9C27B0',
    ];
    final memberSets = const [
      ['Alex', 'Jordan'],
      ['Casey', 'Morgan'],
      ['Riley', 'Sam'],
      ['Taylor', 'Blake'],
      ['Drew', 'Casey'],
      ['Avery', 'Quinn'],
    ];
    final teams = [
      'Debug Dragons',
      'Quantum Penguins',
      'Ctrl+Z Crew',
      'Circuit Goblins',
      'Syntax Sorcerers',
      'Prototype Pirates',
    ].asMap().entries.map((entry) {
      return Team(
        id: '00000000-0000-4000-8000-00000000020${entry.key}',
        classId: classId,
        name: entry.value,
        tableNumber: entry.key + 1,
        points: [12, 9, 11, 8, 10, 7][entry.key],
        accentColor: accentColors[entry.key],
        members: memberSets[entry.key],
        updatedAt: now,
      );
    }).toList();

    final classes = [
      LaunchClass(
        id: classId,
        name: 'AP Comp Sci A - Period 1',
        createdAt: now,
      ),
      LaunchClass(
        id: '00000000-0000-4000-8000-000000000002',
        name: 'Programming for Engineers - Period 2',
        createdAt: now,
      ),
      LaunchClass(
        id: '00000000-0000-4000-8000-000000000003',
        name: 'Honors Physics - Period 3',
        createdAt: now,
      ),
      LaunchClass(
        id: '00000000-0000-4000-8000-000000000003',
        name: 'Computer Science 1 - Period 4',
        createdAt: now,
      ),
      LaunchClass(
        id: '00000000-0000-4000-8000-000000000003',
        name: 'Physics - Period 5',
        createdAt: now,
      ),
      LaunchClass(
        id: '00000000-0000-4000-8000-000000000003',
        name: 'Computer Science 3 - Period 6',
        createdAt: now,
      ),
    ];

    final state = LaunchpadState(
      launchClass: classes.first,
      classes: classes,
      warmup: Warmup(
        id: warmupId,
        classId: classId,
        prompt:
            'A warehouse robot can complete tasks faster by taking more risks. How should its algorithm balance speed vs safety?',
        agenda: const [
          'Warm-up reasoning sprint',
          'Prototype sensor decision trees',
          'Gallery walk and feedback',
          'Exit reflection',
        ],
        active: true,
        createdAt: now,
        updatedAt: now,
      ),
      teams: teams,
      submissions: const [],
      pointEvents: const [],
    );
    await _writeState(state);
  }

  @override
  Future<LaunchpadState> loadState() async {
    await ensureSeeded();
    final raw = _prefs.getString(_stateKey)!;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final classJson = json['class'] as Map<String, dynamic>;
    final launchClass = LaunchClass.fromJson(classJson);
    final classesJson = json['classes'] as List<dynamic>?;
    final classes = classesJson != null
        ? classesJson
            .map((item) => LaunchClass.fromJson(item as Map<String, dynamic>))
            .toList()
        : [launchClass];

    return LaunchpadState(
      launchClass: launchClass,
      classes: classes,
      warmup: Warmup.fromJson(json['warmup'] as Map<String, dynamic>),
      teams: (json['teams'] as List)
          .map((item) => Team.fromJson(item as Map<String, dynamic>))
          .toList(),
      submissions: (json['submissions'] as List)
          .map((item) => Submission.fromJson(item as Map<String, dynamic>))
          .toList(),
      pointEvents: (json['point_events'] as List)
          .map((item) => PointEvent.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<void> savePointEvent(PointEvent event) async {
    final state = await loadState();
    if (state.pointEvents.any(
      (item) => item.clientGeneratedId == event.clientGeneratedId,
    )) {
      return;
    }
    final teams = state.teams.map((team) {
      if (team.id != event.teamId) return team;
      return team.copyWith(
        points: team.points + event.points,
        updatedAt: DateTime.now().toUtc(),
      );
    }).toList();
    await _writeState(
      LaunchpadState(
        launchClass: state.launchClass,
        classes: state.classes,
        warmup: state.warmup,
        teams: teams,
        submissions: state.submissions,
        pointEvents: [...state.pointEvents, event],
      ),
    );
  }

  @override
  Future<void> saveSubmission(Submission submission) async {
    final state = await loadState();
    final existingIndex = state.submissions.indexWhere(
      (item) =>
          item.clientGeneratedId == submission.clientGeneratedId ||
          (item.teamId == submission.teamId &&
              item.warmupId == submission.warmupId),
    );
    final submissions = [...state.submissions];
    if (existingIndex >= 0) {
      submissions[existingIndex] = submission;
    } else {
      submissions.add(submission);
    }
    await _writeState(
      LaunchpadState(
        launchClass: state.launchClass,
        classes: state.classes,
        warmup: state.warmup,
        teams: state.teams,
        submissions: submissions,
        pointEvents: state.pointEvents,
      ),
    );
  }

  @override
  Future<void> saveTeams(List<Team> teams) async {
    final state = await loadState();
    await _writeState(
      LaunchpadState(
        launchClass: state.launchClass,
        classes: state.classes,
        warmup: state.warmup,
        teams: teams,
        submissions: state.submissions,
        pointEvents: state.pointEvents,
      ),
    );
  }

  @override
  Future<void> saveWarmup(Warmup warmup) async {
    final state = await loadState();
    await _writeState(
      LaunchpadState(
        launchClass: state.launchClass,
        classes: state.classes,
        warmup: warmup,
        teams: state.teams,
        submissions: state.submissions,
        pointEvents: state.pointEvents,
      ),
    );
  }

  Future<void> markSynced({
    required Set<String> submissionClientIds,
    required Set<String> pointEventClientIds,
  }) async {
    final state = await loadState();
    final syncedAt = DateTime.now().toUtc();
    await _writeState(
      LaunchpadState(
        launchClass: state.launchClass,
        classes: state.classes,
        warmup: state.warmup,
        teams: state.teams,
        submissions: state.submissions.map((submission) {
          if (!submissionClientIds.contains(submission.clientGeneratedId)) {
            return submission;
          }
          return submission.copyWith(syncedAt: syncedAt);
        }).toList(),
        pointEvents: state.pointEvents.map((event) {
          if (!pointEventClientIds.contains(event.clientGeneratedId)) {
            return event;
          }
          return event.copyWith(syncedAt: syncedAt);
        }).toList(),
      ),
    );
  }

  Future<void> _writeState(LaunchpadState state) async {
    await _prefs.setString(
      _stateKey,
      jsonEncode({
        'class': state.launchClass.toJson(),
        'classes':
            state.classes.map((launchClass) => launchClass.toJson()).toList(),
        'warmup': state.warmup.toJson(),
        'teams': state.teams.map((team) => team.toJson()).toList(),
        'submissions':
            state.submissions.map((submission) => submission.toJson()).toList(),
        'point_events':
            state.pointEvents.map((event) => event.toJson()).toList(),
      }),
    );
  }
}
