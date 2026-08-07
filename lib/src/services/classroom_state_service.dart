import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/launchpad_models.dart';

class ClassroomStateService {
  late final Stream<ClassroomState> _classroomStateStream = _buildStream();

  Stream<ClassroomState> streamClassroomState() => _classroomStateStream;

  Future<void> initializePrototypeRow() async {
    final existing = await Supabase.instance.client
        .from('classroom_state')
        .select('id')
        .eq('id', 1)
        .limit(1)
        .maybeSingle();

    if (existing != null) {
      return;
    }

    final now = DateTime.now().toUtc();
    await Supabase.instance.client.from('classroom_state').insert({
      'id': 1,
      'current_phase_id': null,
      'current_activity': 'Warm-up',
      'timer_status': 'stopped',
      'timer_duration_seconds': 300,
      'timer_remaining_seconds': 300,
      'timer_ends_at': null,
      'updated_at': now.toIso8601String(),
    });
  }

  Future<List<LaunchpadClassRecord>> fetchClasses() async {
    final response =
        await Supabase.instance.client.from('classes').select().order('id');
    return response
        .map<LaunchpadClassRecord>(
            (item) => LaunchpadClassRecord.fromJson(item))
        .toList();
  }

  Future<List<LaunchpadLessonRecord>> fetchLessonsForClass(int classId) async {
    final response = await Supabase.instance.client
        .from('lessons')
        .select()
        .eq('class_id', classId)
        .order('lesson_date', ascending: true)
        .order('id', ascending: true);
    return response
        .map<LaunchpadLessonRecord>(
            (item) => LaunchpadLessonRecord.fromJson(item))
        .toList();
  }

  Future<List<LaunchpadStudentRecord>> fetchStudentsForClass(int classId) async {
    final response = await Supabase.instance.client
        .from('students')
        .select()
        .eq('class_id', classId)
        .order('display_name', ascending: true)
        .order('last_name', ascending: true)
        .order('first_name', ascending: true);
    return response
        .map<LaunchpadStudentRecord>((item) => LaunchpadStudentRecord.fromJson(item))
        .toList();
  }

  Future<List<LaunchpadTableLayoutRecord>> fetchTableLayoutsForClass(int classId) async {
    final response = await Supabase.instance.client
        .from('table_layouts')
        .select()
        .eq('class_id', classId)
        .order('name', ascending: true)
        .order('id', ascending: true);
    return response
        .map<LaunchpadTableLayoutRecord>(
            (item) => LaunchpadTableLayoutRecord.fromJson(item))
        .toList();
  }

  Future<List<LaunchpadTableLayoutMember>> fetchTableLayoutMembers(int layoutId) async {
    final response = await Supabase.instance.client
        .from('table_layout_members')
        .select('student_id, table_number')
        .eq('table_layout_id', layoutId)
        .order('table_number', ascending: true)
        .order('student_id', ascending: true);
    return response
        .map<LaunchpadTableLayoutMember>((item) => LaunchpadTableLayoutMember(
              studentId: item['student_id'] is int
                  ? item['student_id'] as int
                  : int.tryParse(item['student_id']?.toString() ?? '') ?? 0,
              tableNumber: item['table_number'] is int
                  ? item['table_number'] as int
                  : int.tryParse(item['table_number']?.toString() ?? '') ?? 1,
            ))
        .toList();
  }

  Future<LaunchpadTableLayoutRecord> createTableLayout({
    required int classId,
    required String name,
    required int tableCount,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final response = await Supabase.instance.client
        .from('table_layouts')
        .insert({
          'class_id': classId,
          'name': name.trim(),
          'table_count': tableCount,
          'created_at': now,
          'updated_at': now,
        })
        .select()
        .single();
    return LaunchpadTableLayoutRecord.fromJson(response);
  }

  Future<void> saveTableLayoutAssignments({
    required int layoutId,
    required List<LaunchpadTableLayoutMember> members,
  }) async {
    await Supabase.instance.client
        .from('table_layout_members')
        .delete()
        .eq('table_layout_id', layoutId);

    if (members.isEmpty) {
      return;
    }

    final rows = members
        .map((member) => {
              'table_layout_id': layoutId,
              'student_id': member.studentId,
              'table_number': member.tableNumber,
              'created_at': DateTime.now().toUtc().toIso8601String(),
            })
        .toList();
    await Supabase.instance.client.from('table_layout_members').insert(rows);
  }

  Future<void> setActiveTableLayout({
    required int layoutId,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await Supabase.instance.client.from('classroom_state').update({
      'table_layout_id': layoutId,
      'updated_at': now,
    }).eq('id', 1);
  }

  Future<void> updateSelectedClass(int classId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final response = await Supabase.instance.client
        .from('classroom_state')
        .update({
          'class_id': classId,
          'lesson_id': null,
          'table_layout_id': null,
          'updated_at': now,
        })
        .eq('id', 1)
        .select();
    debugPrint(
        '[Supabase] selected class updated -> ${response.length} row(s)');
  }

  Future<void> updateSelectedLesson(int lessonId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final response = await Supabase.instance.client
        .from('classroom_state')
        .update({
          'lesson_id': lessonId,
          'current_phase_id': null,
          'current_activity': '',
          'updated_at': now,
        })
        .eq('id', 1)
        .select();
    debugPrint(
        '[Supabase] selected lesson updated -> ${response.length} row(s)');
  }

  Future<LaunchpadLessonRecord> createLesson({
    required int classId,
    required DateTime lessonDate,
    required String title,
  }) async {
    final payload = {
      'class_id': classId,
      'lesson_date': lessonDate.toUtc().toIso8601String(),
      'title': title.trim(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final response = await Supabase.instance.client
        .from('lessons')
        .insert(payload)
        .select()
        .single();
    return LaunchpadLessonRecord.fromJson(response);
  }

  Future<Map<String, dynamic>?> fetchLessonDocument(int lessonId) async {
    final response = await Supabase.instance.client
        .from('lessons')
        .select('id, class_id, title, lesson_date, lesson_json')
        .eq('id', lessonId)
        .maybeSingle();
    if (response == null) {
      return null;
    }
    final lessonJson = response['lesson_json'];
    if (lessonJson is Map) {
      return Map<String, dynamic>.from(lessonJson);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchLessonPhases(int lessonId) async {
    final response = await Supabase.instance.client
        .from('lesson_phases')
        .select()
        .eq('lesson_id', lessonId)
        .order('sort_order', ascending: true)
        .order('id', ascending: true);
    return response
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> saveLessonDocument({
    required int lessonId,
    required int classId,
    required DateTime lessonDate,
    required String title,
    required Map<String, dynamic> lessonJson,
    required List<LessonPhase> phases,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await Supabase.instance.client.from('lessons').update({
      'class_id': classId,
      'lesson_date': lessonDate.toUtc().toIso8601String(),
      'title': title.trim(),
      'lesson_json': lessonJson,
      'updated_at': now,
    }).eq('id', lessonId);

    await Supabase.instance.client.from('lesson_phases').delete().eq('lesson_id', lessonId);

    final phaseRows = <Map<String, dynamic>>[];
    for (var index = 0; index < phases.length; index++) {
      final phase = phases[index];
      phaseRows.add({
        'lesson_id': lessonId,
        'phase_key': phase.id,
        'title': phase.title,
        'phase_type': phase.type,
        'prompt': phase.prompt,
        'instructions': phase.instructions,
        'duration_seconds': phase.durationSeconds,
        'sort_order': index,
        'submission_mode': phase.submission.mode,
        'phase_json': phase.rawJson,
        'created_at': now,
        'updated_at': now,
      });
    }
    if (phaseRows.isNotEmpty) {
      await Supabase.instance.client.from('lesson_phases').insert(phaseRows);
    }
  }

  Future<void> updateCurrentPhase({
    required String phaseId,
    required String activityTitle,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final response = await Supabase.instance.client
        .from('classroom_state')
        .update({
          'current_phase_id': phaseId,
          'current_activity': activityTitle,
          'updated_at': now,
        })
        .eq('id', 1)
        .select();
    debugPrint('[Supabase] phase updated: $phaseId / $activityTitle');
    debugPrint(
        '[Supabase] updated row -> ${response.isNotEmpty ? response.first : 'none'}');
  }

  Future<void> startLiveClass() async {
    final now = DateTime.now().toUtc().toIso8601String();
    final response = await Supabase.instance.client
        .from('classroom_state')
        .update({
          'is_live': true,
          'updated_at': now,
        })
        .eq('id', 1)
        .select();
    debugPrint('[Supabase] live class started');
    debugPrint(
        '[Supabase] updated row -> ${response.isNotEmpty ? response.first : 'none'}');
  }

  Future<void> endLiveClass() async {
    final now = DateTime.now().toUtc().toIso8601String();
    final response = await Supabase.instance.client
        .from('classroom_state')
        .update({
          'is_live': false,
          'updated_at': now,
        })
        .eq('id', 1)
        .select();
    debugPrint('[Supabase] live class ended');
    debugPrint(
        '[Supabase] updated row -> ${response.isNotEmpty ? response.first : 'none'}');
  }

  Future<void> updateCurrentActivity(String activity) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final response = await Supabase.instance.client
        .from('classroom_state')
        .update({
          'current_activity': activity,
          'updated_at': now,
        })
        .eq('id', 1)
        .select();
    debugPrint(
        '[Supabase] current_activity updated -> ${response.length} row(s)');
  }

  Future<void> startTimer({required int durationSeconds}) async {
    final now = DateTime.now().toUtc();
    final endsAt = now.add(Duration(seconds: durationSeconds));
    final response = await Supabase.instance.client
        .from('classroom_state')
        .update({
          'timer_status': 'running',
          'timer_duration_seconds': durationSeconds,
          'timer_remaining_seconds': durationSeconds,
          'timer_ends_at': endsAt.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .eq('id', 1)
        .select();
    debugPrint('[Supabase] timer started -> ${response.length} row(s)');
  }

  Future<void> pauseTimer({required int remainingSeconds}) async {
    final now = DateTime.now().toUtc();
    final response = await Supabase.instance.client
        .from('classroom_state')
        .update({
          'timer_status': 'paused',
          'timer_remaining_seconds': remainingSeconds.clamp(0, 86400),
          'timer_ends_at': null,
          'updated_at': now.toIso8601String(),
        })
        .eq('id', 1)
        .select();
    debugPrint('[Supabase] timer paused -> ${response.length} row(s)');
  }

  Future<void> resumeTimer({required int remainingSeconds}) async {
    final now = DateTime.now().toUtc();
    final endsAt = now.add(Duration(seconds: remainingSeconds));
    final response = await Supabase.instance.client
        .from('classroom_state')
        .update({
          'timer_status': 'running',
          'timer_remaining_seconds': remainingSeconds.clamp(0, 86400),
          'timer_ends_at': endsAt.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .eq('id', 1)
        .select();
    debugPrint('[Supabase] timer resumed -> ${response.length} row(s)');
  }

  Future<void> resetTimer({required int durationSeconds}) async {
    final now = DateTime.now().toUtc();
    final response = await Supabase.instance.client
        .from('classroom_state')
        .update({
          'timer_status': 'stopped',
          'timer_duration_seconds': durationSeconds,
          'timer_remaining_seconds': durationSeconds,
          'timer_ends_at': null,
          'updated_at': now.toIso8601String(),
        })
        .eq('id', 1)
        .select();
    debugPrint('[Supabase] timer reset -> ${response.length} row(s)');
  }

  Stream<ClassroomState> _buildStream() {
    return Supabase.instance.client
        .from('classroom_state')
        .stream(primaryKey: ['id'])
        .eq('id', 1)
        .map((rows) {
          if (rows.isEmpty) {
            debugPrint('[Supabase] stream emitted no classroom_state rows');
            return const ClassroomState();
          }
          final row = rows.first;
          debugPrint('[Supabase] stream row: $row');
          return ClassroomState.fromJson(row);
        })
        .handleError((Object error, StackTrace stackTrace) {
          debugPrint('[Supabase] stream error: $error');
        });
  }
}
