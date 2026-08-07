import 'package:flutter/material.dart';

import '../../services/launchpad_controller.dart';
import '../widgets/launchpad_role_header.dart';
import '../widgets/status_pill.dart';
import 'classroom_display_screen.dart';
import 'team_submission_screen.dart';

class StudentShell extends StatelessWidget {
  const StudentShell({super.key, required this.controller});

  final LaunchpadController controller;

  @override
  Widget build(BuildContext context) {
    final selectedClassName =
        controller.selectedPersistedClass?.displayName ?? 'No class selected';
    final selectedLessonName =
        controller.selectedPersistedLesson?.displayLabel ?? 'No lesson selected';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF0D1117),
          toolbarHeight: 78,
          title: LaunchpadRoleHeader(
            roleLabel: 'Student',
            classes: controller.persistedClasses,
            selectedClassId: controller.selectedPersistedClass?.id,
            onClassChanged: null,
            lessons: controller.persistedLessons,
            selectedLessonId: controller.selectedPersistedLesson?.id,
            onLessonChanged: null,
            statusLabel: controller.liveStatusLabel,
            statusColor: controller.liveStatusColor,
            roleModeLabel: 'Student Mode',
            centerContent: Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _ReadOnlyHeaderField(
                      label: 'Class',
                      value: selectedClassName,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ReadOnlyHeaderField(
                      label: 'Lesson',
                      value: selectedLessonName,
                    ),
                  ),
                ],
              ),
            ),
            trailingContent: StatusPill(
              label: controller.liveStatusLabel,
              color: controller.liveStatusColor,
              onTap: controller.canToggleFollow
                  ? controller.toggleFollowClass
                  : null,
            ),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Class'),
              Tab(text: 'Submit'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ClassroomDisplayScreen(
              controller: controller,
              showTeacherControls: false,
            ),
            TeamSubmissionScreen(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyHeaderField extends StatelessWidget {
  const _ReadOnlyHeaderField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1D232C),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.85),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
