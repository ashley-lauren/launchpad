import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/launchpad_models.dart';
import 'launchpad_repository.dart';

class SupabaseRepository implements LaunchpadRepository {
  SupabaseRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<LaunchpadState> loadState() async {
    final classesData = await _client.from('classes').select();
    if (classesData.isEmpty) {
      throw StateError('No Supabase class is configured.');
    }
    final classes = classesData
        .map<LaunchClass>((item) => LaunchClass.fromJson(item))
        .toList();
    final launchClass = classes.first;
    final warmups = await _client
        .from('warmups')
        .select()
        .eq('class_id', launchClass.id)
        .eq('active', true)
        .order('created_at', ascending: false)
        .limit(1);
    final teams = await _client
        .from('teams')
        .select()
        .eq('class_id', launchClass.id)
        .order('table_number');
    final warmup = Warmup.fromJson(warmups.first);
    final submissions = await _client
        .from('submissions')
        .select()
        .eq('warmup_id', warmup.id)
        .order('submitted_at');
    final pointEvents = await _client
        .from('point_events')
        .select()
        .eq('warmup_id', warmup.id)
        .order('created_at');

    return LaunchpadState(
      launchClass: launchClass,
      classes: classes,
      warmup: warmup,
      teams: teams.map<Team>((item) => Team.fromJson(item)).toList(),
      submissions: submissions
          .map<Submission>((item) => Submission.fromJson(item))
          .toList(),
      pointEvents: pointEvents
          .map<PointEvent>((item) => PointEvent.fromJson(item))
          .toList(),
    );
  }

  @override
  Future<void> savePointEvent(PointEvent event) async {
    await _client.rpc(
      'record_point_event_once',
      params: {
        'event_id': event.id,
        'target_team_id': event.teamId,
        'target_warmup_id': event.warmupId,
        'event_reason': event.reason,
        'point_delta': event.points,
        'event_client_generated_id': event.clientGeneratedId,
        'event_created_at': event.createdAt.toIso8601String(),
      },
    );
  }

  @override
  Future<void> saveSubmission(Submission submission) async {
    await _client
        .from('submissions')
        .upsert(submission.toJson(), onConflict: 'warmup_id,team_id');
  }

  @override
  Future<void> saveTeams(List<Team> teams) async {
    await _client
        .from('teams')
        .upsert(teams.map((team) => team.toJson()).toList(), onConflict: 'id');
  }

  @override
  Future<void> saveWarmup(Warmup warmup) async {
    await _client.from('warmups').upsert(warmup.toJson(), onConflict: 'id');
  }
}
