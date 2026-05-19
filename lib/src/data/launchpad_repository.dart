import '../models/launchpad_models.dart';

abstract class LaunchpadRepository {
  Future<LaunchpadState> loadState();
  Future<void> saveWarmup(Warmup warmup);
  Future<void> saveSubmission(Submission submission);
  Future<void> savePointEvent(PointEvent event);
  Future<void> saveTeams(List<Team> teams);
}
