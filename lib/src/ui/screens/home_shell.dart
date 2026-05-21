import 'package:flutter/material.dart';

import '../../services/launchpad_controller.dart';
import '../widgets/status_pill.dart';
import 'classroom_display_screen.dart';
import 'teacher_dashboard_screen.dart';
import 'team_submission_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.controller});

  final LaunchpadController controller;

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDate(DateTime date) {
    final month = _monthNames[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final launchClass = controller.state.launchClass;
    final lessonInfo = controller.state.activeLesson?.lessonInfo;
    final titleLabel = lessonInfo == null
        ? '${launchClass.name} · ${_formatDate(DateTime.now())}'
        : [
            if (lessonInfo.course.isNotEmpty) lessonInfo.course,
            if (lessonInfo.period.isNotEmpty) lessonInfo.period,
            if (lessonInfo.date.isNotEmpty) lessonInfo.date,
          ].join(' · ');

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1117),
          title: Row(
            children: [
              const Text(
                'Launchpad',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "// $titleLabel",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: StatusPill(status: controller.syncStatus),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Display'),
              Tab(text: 'Team Submit'),
              Tab(text: 'Teacher'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ClassroomDisplayScreen(controller: controller),
            TeamSubmissionScreen(controller: controller),
            TeacherDashboardScreen(controller: controller),
          ],
        ),
      ),
    );
  }
}
