import 'package:flutter/material.dart';

import '../../services/launchpad_controller.dart';
import '../theme.dart';
import '../widgets/launchpad_role_header.dart';
import '../widgets/status_pill.dart';
import 'classroom_display_screen.dart';

class TeacherShell extends StatelessWidget {
  const TeacherShell({super.key, required this.controller});

  final LaunchpadController controller;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF0D1117),
          toolbarHeight: 78,
          title: LaunchpadRoleHeader(
            roleLabel: 'Teacher',
            classes: controller.persistedClasses,
            selectedClassId: controller.selectedPersistedClass?.id,
            onClassChanged: (value) {
              controller.updateSelectedClass(value);
            },
            lessons: controller.persistedLessons,
            roleModeLabel: 'Teacher Mode',
            selectedLessonId: controller.selectedPersistedLesson?.id,
            onLessonChanged: (value) {
              controller.updateSelectedLesson(value);
            },
            statusLabel: controller.isLive ? 'Live' : 'Not Live',
            statusColor: controller.isLive
                ? const Color(0xFF7EE787)
                : const Color(0xFF8B949E),
            trailingContent: StatusPill(
              label: controller.isLive ? 'Live' : 'Not Live',
              color: controller.isLive
                  ? const Color(0xFF7EE787)
                  : const Color(0xFF8B949E),
            ),
            classIsLoading: controller.classesLoading,
            classError: controller.classesError,
            lessonIsLoading: controller.lessonsLoading,
            lessonError: controller.lessonsError,
            classHintText: 'Select class',
            lessonHintText: 'Select lesson',
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Class'),
              Tab(text: 'Submissions'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TeacherClassView(controller: controller),
            _TeacherSubmissionsView(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _TeacherClassView extends StatelessWidget {
  const _TeacherClassView({required this.controller});

  final LaunchpadController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClassroomDisplayScreen(
          controller: controller,
          showTeacherControls: true,
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: _TeacherFloatingControls(controller: controller),
        ),
      ],
    );
  }
}

class _TeacherFloatingControls extends StatelessWidget {
  const _TeacherFloatingControls({required this.controller});

  final LaunchpadController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'teacher-prev-phase',
          onPressed: controller.state.currentPhaseIndex <= 0
              ? null
              : controller.previousPhase,
          backgroundColor: controller.state.currentPhaseIndex <= 0
              ? Colors.grey[600]
              : Theme.of(context).colorScheme.secondary,
          foregroundColor: Colors.black87,
          child: const Icon(Icons.arrow_upward),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.small(
          heroTag: 'teacher-timer-toggle',
          onPressed: () {
            if (controller.timerRunning) {
              controller.pauseTimer();
            } else if (controller.timerPaused) {
              controller.resumeTimer();
            } else {
              controller.startTimer();
            }
          },
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          foregroundColor: Colors.black87,
          child: Icon(
            controller.timerRunning
                ? Icons.pause
                : controller.timerPaused
                    ? Icons.play_arrow
                    : Icons.play_arrow,
          ),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'teacher-next-phase',
          onPressed: (controller.state.activeLesson?.phases.isEmpty ?? true) ||
                  controller.state.currentPhaseIndex >=
                      (controller.state.activeLesson?.phases.length ?? 0) - 1
              ? null
              : controller.nextPhase,
          backgroundColor: (controller.state.activeLesson?.phases.isEmpty ??
                      true) ||
                  controller.state.currentPhaseIndex >=
                      (controller.state.activeLesson?.phases.length ?? 0) - 1
              ? Colors.grey[600]
              : Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.black87,
          child: const Icon(Icons.arrow_downward),
        ),
      ],
    );
  }
}

class _TeacherSubmissionsView extends StatelessWidget {
  const _TeacherSubmissionsView({required this.controller});

  final LaunchpadController controller;

  @override
  Widget build(BuildContext context) {
    final submissions = controller.state.submissions;
    final teams = controller.state.teams;
    final teamById = {
      for (final team in teams) team.id: 'Table ${team.tableNumber}'
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Submissions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              if (submissions.isEmpty)
                const Text(
                  'No submissions yet.',
                  style: TextStyle(color: Color(0xFF8B949E)),
                )
              else
                for (final submission in submissions.reversed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF30363D)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${teamById[submission.teamId] ?? submission.teamId} / ${submission.confidence} confidence',
                              style: TextStyle(
                                color: teamAccentColor(
                                  teams.firstWhere(
                                    (item) => item.id == submission.teamId,
                                    orElse: () => teams.first,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(submission.answer),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
