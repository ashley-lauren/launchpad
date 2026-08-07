import 'package:flutter_test/flutter_test.dart';
import 'package:launchpad/src/models/launchpad_models.dart';

void main() {
  group('LaunchpadState phase lookup', () {
    test('finds a phase index from a stable phase id', () {
      const lesson = Lesson(
        lessonInfo: LessonInfo(
          title: 'Test Lesson',
          course: '',
          period: '',
          date: '',
          rawJson: {},
        ),
        displaySettings: DisplaySettings(
          showLeaderboard: true,
          showTeamMap: true,
          showAgenda: true,
          showClock: true,
          rawJson: {},
        ),
        standards: [],
        learningObjectives: [],
        successCriteria: [],
        vocabulary: [],
        materials: [],
        differentiation: {},
        teacherMoves: {},
        pointRewards: [],
        phases: [
          LessonPhase(
            id: 'hook_01',
            type: 'warmup',
            title: 'Hook',
            durationSeconds: 300,
            prompt: '',
            instructions: [],
            submission: LessonSubmissionSettings(
              enabled: false,
              mode: 'team',
              confidenceSelector: false,
              rawJson: {},
            ),
            teacherNotes: [],
            display: {},
            discussionPrompts: [],
            reflectionQuestions: [],
            keyIdeas: [],
            keyActions: [],
            rawJson: {},
          ),
          LessonPhase(
            id: 'debugging_01',
            type: 'challenge',
            title: 'Debug the Broken Robot',
            durationSeconds: 600,
            prompt: '',
            instructions: [],
            submission: LessonSubmissionSettings(
              enabled: false,
              mode: 'team',
              confidenceSelector: false,
              rawJson: {},
            ),
            teacherNotes: [],
            display: {},
            discussionPrompts: [],
            reflectionQuestions: [],
            keyIdeas: [],
            keyActions: [],
            rawJson: {},
          ),
        ],
        rawJson: {},
      );

      final state = LaunchpadState(
        launchClass: LaunchClass(
          id: 'class-1',
          name: 'Class',
          createdAt: DateTime.utc(2024, 1, 1),
        ),
        classes: const [],
        warmup: Warmup(
          id: 'warmup-1',
          classId: 'class-1',
          prompt: 'Prompt',
          agenda: const [],
          active: true,
          createdAt: DateTime.utc(2024, 1, 1),
          updatedAt: DateTime.utc(2024, 1, 1),
        ),
        teams: const [],
        submissions: const [],
        pointEvents: const [],
        activeLesson: lesson,
        currentPhaseIndex: 0,
      );

      expect(state.phaseIndexForId('debugging_01'), 1);
      expect(state.phaseIndexForId('missing'), isNull);
    });
  });
}
