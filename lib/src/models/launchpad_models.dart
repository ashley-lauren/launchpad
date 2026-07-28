class AgendaItem {
  const AgendaItem({
    required this.title,
    required this.durationMinutes,
  });

  final String title;
  final int durationMinutes;

  factory AgendaItem.fromJson(Map<String, dynamic> json) => AgendaItem(
        title: json['title'] as String? ?? json.toString(),
        durationMinutes: json['duration_minutes'] as int? ?? 5,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'duration_minutes': durationMinutes,
      };
}

class Lesson {
  const Lesson({
    required this.lessonInfo,
    required this.displaySettings,
    required this.standards,
    required this.learningObjectives,
    required this.successCriteria,
    required this.vocabulary,
    required this.materials,
    required this.differentiation,
    required this.teacherMoves,
    required this.pointRewards,
    required this.phases,
    required this.rawJson,
  });

  final LessonInfo lessonInfo;
  final DisplaySettings displaySettings;
  final List<Map<String, dynamic>> standards;
  final List<String> learningObjectives;
  final List<String> successCriteria;
  final List<String> vocabulary;
  final List<String> materials;
  final Map<String, dynamic> differentiation;
  final Map<String, dynamic> teacherMoves;
  final List<Map<String, dynamic>> pointRewards;
  final List<LessonPhase> phases;
  final Map<String, dynamic> rawJson;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      lessonInfo: LessonInfo.fromJson(_asMap(json['lessonInfo'])),
      displaySettings: DisplaySettings.fromJson(
        _asMap(json['displaySettings']),
      ),
      standards: _asMapList(json['standards']),
      learningObjectives: _asStringList(json['learningObjectives']),
      successCriteria: _asStringList(json['successCriteria']),
      vocabulary: _asStringList(json['vocabulary']),
      materials: _asStringList(json['materials']),
      differentiation: _asMap(json['differentiation']),
      teacherMoves: _asMap(json['teacherMoves']),
      pointRewards: _asMapList(json['pointRewards']),
      phases: _asMapList(json['phases'])
          .map((item) => LessonPhase.fromJson(item))
          .toList(),
      rawJson: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => rawJson;
}

class LessonInfo {
  const LessonInfo({
    required this.title,
    required this.course,
    required this.period,
    required this.date,
    required this.rawJson,
  });

  final String title;
  final String course;
  final String period;
  final String date;
  final Map<String, dynamic> rawJson;

  factory LessonInfo.fromJson(Map<String, dynamic> json) => LessonInfo(
        title: json['title']?.toString() ?? 'Untitled Lesson',
        course: json['course']?.toString() ?? '',
        period: json['period']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        rawJson: Map<String, dynamic>.from(json),
      );
}

class DisplaySettings {
  const DisplaySettings({
    required this.showLeaderboard,
    required this.showTeamMap,
    required this.showAgenda,
    required this.showClock,
    required this.rawJson,
  });

  final bool showLeaderboard;
  final bool showTeamMap;
  final bool showAgenda;
  final bool showClock;
  final Map<String, dynamic> rawJson;

  factory DisplaySettings.fromJson(Map<String, dynamic> json) =>
      DisplaySettings(
        showLeaderboard: json['showLeaderboard'] as bool? ?? true,
        showTeamMap: json['showTeamMap'] as bool? ?? true,
        showAgenda: json['showAgenda'] as bool? ?? true,
        showClock: json['showClock'] as bool? ?? true,
        rawJson: Map<String, dynamic>.from(json),
      );
}

class LessonSubmissionSettings {
  const LessonSubmissionSettings({
    required this.enabled,
    required this.mode,
    required this.confidenceSelector,
    required this.rawJson,
  });

  final bool enabled;
  final String mode;
  final bool confidenceSelector;
  final Map<String, dynamic> rawJson;

  factory LessonSubmissionSettings.fromJson(Map<String, dynamic> json) =>
      LessonSubmissionSettings(
        enabled: json['enabled'] as bool? ?? false,
        mode: json['mode']?.toString() ?? 'team',
        confidenceSelector: json['confidenceSelector'] as bool? ?? false,
        rawJson: Map<String, dynamic>.from(json),
      );
}

class LessonPhase {
  const LessonPhase({
    required this.id,
    required this.type,
    required this.title,
    required this.durationSeconds,
    required this.prompt,
    required this.instructions,
    required this.submission,
    required this.teacherNotes,
    required this.display,
    required this.discussionPrompts,
    required this.reflectionQuestions,
    required this.keyIdeas,
    required this.keyActions,
    required this.rawJson,
  });

  final String id;
  final String type;
  final String title;
  final int durationSeconds;
  final String prompt;
  final List<String> instructions;
  final LessonSubmissionSettings submission;
  final List<String> teacherNotes;
  final Map<String, dynamic> display;
  final List<String> discussionPrompts;
  final List<String> reflectionQuestions;
  final List<String> keyIdeas;
  final List<String> keyActions;
  final Map<String, dynamic> rawJson;

  factory LessonPhase.fromJson(Map<String, dynamic> json) {
    return LessonPhase(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'phase',
      title: json['title']?.toString() ?? 'Untitled Phase',
      durationSeconds: json['durationSeconds'] as int? ?? 300,
      prompt: json['prompt']?.toString() ?? '',
      instructions: _asStringList(json['instructions']),
      submission: LessonSubmissionSettings.fromJson(
        _asMap(json['submission']),
      ),
      teacherNotes: _asStringList(json['teacherNotes']),
      display: _asMap(json['display']),
      discussionPrompts: _asStringList(json['discussionPrompts']),
      reflectionQuestions: _asStringList(json['reflectionQuestions']),
      keyIdeas: _asStringList(json['keyIdeas']),
      keyActions: _asStringList(json['keyActions']),
      rawJson: Map<String, dynamic>.from(json),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Map<String, dynamic>> _asMapList(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => _asMap(item)).toList();
}

List<String> _asStringList(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList();
}

class LaunchClass {
  const LaunchClass({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  factory LaunchClass.fromJson(Map<String, dynamic> json) => LaunchClass(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'created_at': createdAt.toIso8601String(),
      };
}

class Team {
  const Team({
    required this.id,
    required this.classId,
    required this.name,
    required this.tableNumber,
    required this.points,
    required this.updatedAt,
    this.accentColor,
    this.members = const [],
  });

  final String id;
  final String classId;
  final String name;
  final int tableNumber;
  final int points;
  final DateTime updatedAt;
  final String? accentColor;
  final List<String> members;

  Team copyWith({
    int? points,
    String? accentColor,
    DateTime? updatedAt,
    List<String>? members,
    String? name,
  }) =>
      Team(
        id: id,
        classId: classId,
        name: name ?? this.name,
        tableNumber: tableNumber,
        points: points ?? this.points,
        updatedAt: updatedAt ?? this.updatedAt,
        accentColor: accentColor ?? this.accentColor,
        members: members ?? this.members,
      );

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        classId: json['class_id'] as String,
        name: json['name'] as String,
        tableNumber: json['table_number'] as int,
        points: json['points'] as int? ?? 0,
        updatedAt: DateTime.parse(json['updated_at'] as String),
        accentColor: json['accent_color'] as String?,
        members: (json['members'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'class_id': classId,
        'name': name,
        'table_number': tableNumber,
        'points': points,
        'accent_color': accentColor,
        'members': members,
        'updated_at': updatedAt.toIso8601String(),
      };
}

class Warmup {
  const Warmup({
    required this.id,
    required this.classId,
    required this.prompt,
    required this.agenda,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String classId;
  final String prompt;
  final List<AgendaItem> agenda;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  Warmup copyWith({
    String? prompt,
    List<AgendaItem>? agenda,
    DateTime? updatedAt,
  }) =>
      Warmup(
        id: id,
        classId: classId,
        prompt: prompt ?? this.prompt,
        agenda: agenda ?? this.agenda,
        active: active,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory Warmup.fromJson(Map<String, dynamic> json) {
    final agendaData = json['agenda'] as List<dynamic>? ?? [];
    final agenda = agendaData.map((item) {
      if (item is Map<String, dynamic>) {
        return AgendaItem.fromJson(item);
      } else if (item is String) {
        return AgendaItem(title: item, durationMinutes: 5);
      }
      return AgendaItem(title: item.toString(), durationMinutes: 5);
    }).toList();

    return Warmup(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      prompt: json['prompt'] as String,
      agenda: agenda,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'class_id': classId,
        'prompt': prompt,
        'agenda': agenda.map((item) => item.toJson()).toList(),
        'active': active,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class Submission {
  const Submission({
    required this.id,
    required this.warmupId,
    required this.teamId,
    required this.answer,
    required this.confidence,
    required this.clientGeneratedId,
    required this.submittedAt,
    this.syncedAt,
    this.contributors = const [],
  });

  final String id;
  final String warmupId;
  final String teamId;
  final String answer;
  final String confidence;
  final String clientGeneratedId;
  final DateTime submittedAt;
  final DateTime? syncedAt;
  final List<String> contributors;

  Submission copyWith({DateTime? syncedAt, List<String>? contributors}) =>
      Submission(
        id: id,
        warmupId: warmupId,
        teamId: teamId,
        answer: answer,
        confidence: confidence,
        clientGeneratedId: clientGeneratedId,
        submittedAt: submittedAt,
        syncedAt: syncedAt ?? this.syncedAt,
        contributors: contributors ?? this.contributors,
      );

  factory Submission.fromJson(Map<String, dynamic> json) => Submission(
        id: json['id'] as String,
        warmupId: json['warmup_id'] as String,
        teamId: json['team_id'] as String,
        answer: json['answer'] as String,
        confidence: json['confidence'] as String,
        clientGeneratedId: json['client_generated_id'] as String,
        submittedAt: DateTime.parse(json['submitted_at'] as String),
        syncedAt: json['synced_at'] == null
            ? null
            : DateTime.parse(json['synced_at'] as String),
        contributors: (json['contributors'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            (json['contributor_ids'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'warmup_id': warmupId,
        'team_id': teamId,
        'answer': answer,
        'confidence': confidence,
        'client_generated_id': clientGeneratedId,
        'submitted_at': submittedAt.toIso8601String(),
        'synced_at': syncedAt?.toIso8601String(),
        'contributors': contributors,
        'contributor_ids': contributors,
      };
}

class PointEvent {
  const PointEvent({
    required this.id,
    required this.teamId,
    required this.warmupId,
    required this.reason,
    required this.points,
    required this.clientGeneratedId,
    required this.createdAt,
    this.syncedAt,
  });

  final String id;
  final String teamId;
  final String warmupId;
  final String reason;
  final int points;
  final String clientGeneratedId;
  final DateTime createdAt;
  final DateTime? syncedAt;

  PointEvent copyWith({DateTime? syncedAt}) => PointEvent(
        id: id,
        teamId: teamId,
        warmupId: warmupId,
        reason: reason,
        points: points,
        clientGeneratedId: clientGeneratedId,
        createdAt: createdAt,
        syncedAt: syncedAt ?? this.syncedAt,
      );

  factory PointEvent.fromJson(Map<String, dynamic> json) => PointEvent(
        id: json['id'] as String,
        teamId: json['team_id'] as String,
        warmupId: json['warmup_id'] as String,
        reason: json['reason'] as String,
        points: json['points'] as int,
        clientGeneratedId: json['client_generated_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        syncedAt: json['synced_at'] == null
            ? null
            : DateTime.parse(json['synced_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'team_id': teamId,
        'warmup_id': warmupId,
        'reason': reason,
        'points': points,
        'client_generated_id': clientGeneratedId,
        'created_at': createdAt.toIso8601String(),
        'synced_at': syncedAt?.toIso8601String(),
      };
}

class LaunchpadState {
  const LaunchpadState({
    required this.launchClass,
    required this.classes,
    required this.warmup,
    required this.teams,
    required this.submissions,
    required this.pointEvents,
    this.activeLesson,
    this.currentPhaseIndex = 0,
  });

  final LaunchClass launchClass;
  final List<LaunchClass> classes;
  final Warmup warmup;
  final List<Team> teams;
  final List<Submission> submissions;
  final List<PointEvent> pointEvents;
  final Lesson? activeLesson;
  final int currentPhaseIndex;

  LessonPhase? get currentPhase {
    final lesson = activeLesson;
    if (lesson == null || lesson.phases.isEmpty) return null;
    final index = currentPhaseIndex.clamp(0, lesson.phases.length - 1);
    return lesson.phases[index];
  }

  LaunchpadState copyWith({
    LaunchClass? launchClass,
    List<LaunchClass>? classes,
    Warmup? warmup,
    List<Team>? teams,
    List<Submission>? submissions,
    List<PointEvent>? pointEvents,
    Lesson? activeLesson,
    int? currentPhaseIndex,
  }) {
    return LaunchpadState(
      launchClass: launchClass ?? this.launchClass,
      classes: classes ?? this.classes,
      warmup: warmup ?? this.warmup,
      teams: teams ?? this.teams,
      submissions: submissions ?? this.submissions,
      pointEvents: pointEvents ?? this.pointEvents,
      activeLesson: activeLesson ?? this.activeLesson,
      currentPhaseIndex: currentPhaseIndex ?? this.currentPhaseIndex,
    );
  }
}
