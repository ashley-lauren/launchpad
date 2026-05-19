import 'dart:convert';

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
  final List<String> agenda;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  Warmup copyWith({
    String? prompt,
    List<String>? agenda,
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

  factory Warmup.fromJson(Map<String, dynamic> json) => Warmup(
        id: json['id'] as String,
        classId: json['class_id'] as String,
        prompt: json['prompt'] as String,
        agenda: (jsonDecode(jsonEncode(json['agenda'])) as List)
            .map((item) => item.toString())
            .toList(),
        active: json['active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'class_id': classId,
        'prompt': prompt,
        'agenda': agenda,
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
  });

  final String id;
  final String warmupId;
  final String teamId;
  final String answer;
  final String confidence;
  final String clientGeneratedId;
  final DateTime submittedAt;
  final DateTime? syncedAt;

  Submission copyWith({DateTime? syncedAt}) => Submission(
        id: id,
        warmupId: warmupId,
        teamId: teamId,
        answer: answer,
        confidence: confidence,
        clientGeneratedId: clientGeneratedId,
        submittedAt: submittedAt,
        syncedAt: syncedAt ?? this.syncedAt,
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
  });

  final LaunchClass launchClass;
  final List<LaunchClass> classes;
  final Warmup warmup;
  final List<Team> teams;
  final List<Submission> submissions;
  final List<PointEvent> pointEvents;

  LaunchpadState copyWith({
    LaunchClass? launchClass,
    List<LaunchClass>? classes,
    Warmup? warmup,
    List<Team>? teams,
    List<Submission>? submissions,
    List<PointEvent>? pointEvents,
  }) {
    return LaunchpadState(
      launchClass: launchClass ?? this.launchClass,
      classes: classes ?? this.classes,
      warmup: warmup ?? this.warmup,
      teams: teams ?? this.teams,
      submissions: submissions ?? this.submissions,
      pointEvents: pointEvents ?? this.pointEvents,
    );
  }
}
