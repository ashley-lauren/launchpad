import 'package:flutter/material.dart';

import '../../services/launchpad_controller.dart';
import '../widgets/status_pill.dart';
import 'classroom_display_screen.dart';
import 'teacher_dashboard_screen.dart';
import 'team_submission_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final LaunchpadController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentTabIndex = 0;

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
    final launchClass = widget.controller.state.launchClass;
    final lessonInfo = widget.controller.state.activeLesson?.lessonInfo;
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
              child: StatusPill(status: widget.controller.syncStatus),
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Display'),
              Tab(text: 'Team Submit'),
              Tab(text: 'Teacher'),
            ],
            onTap: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
          ),
        ),
        body: TabBarView(
          children: [
            ClassroomDisplayScreen(controller: widget.controller),
            TeamSubmissionScreen(controller: widget.controller),
            TeacherDashboardScreen(controller: widget.controller),
          ],
        ),
        floatingActionButton: (_currentTabIndex == 0 || _currentTabIndex == 2)
            ? Stack(
                children: [
                  Positioned(
                    bottom: 0,
                    right: 64,
                    child: FloatingActionButton.small(
                      onPressed:
                          (_currentTabIndex == 0 || _currentTabIndex == 2)
                              ? (widget.controller.timerRunning
                                  ? widget.controller.pauseTimer
                                  : widget.controller.startTimer)
                              : null,
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      foregroundColor: Colors.black87,
                      child: Icon(
                        widget.controller.timerRunning
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 64,
                    right: 0,
                    child: FloatingActionButton.small(
                      onPressed:
                          (_currentTabIndex == 0 || _currentTabIndex == 2)
                              ? (widget.controller.state.currentPhaseIndex <= 0
                                  ? null
                                  : widget.controller.previousPhase)
                              : null,
                      backgroundColor:
                          widget.controller.state.currentPhaseIndex <= 0
                              ? Colors.grey[600]
                              : Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.black87,
                      child: const Icon(Icons.arrow_upward),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: FloatingActionButton(
                      onPressed: (widget.controller.state.activeLesson?.phases
                                      .isEmpty ??
                                  true) ||
                              widget.controller.state.currentPhaseIndex >=
                                  (widget.controller.state.activeLesson?.phases
                                              .length ??
                                          0) -
                                      1
                          ? null
                          : widget.controller.nextPhase,
                      backgroundColor: (widget.controller.state.activeLesson
                                      ?.phases.isEmpty ??
                                  true) ||
                              widget.controller.state.currentPhaseIndex >=
                                  (widget.controller.state.activeLesson?.phases
                                              .length ??
                                          0) -
                                      1
                          ? Colors.grey[600]
                          : Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black87,
                      child: const Icon(Icons.arrow_downward),
                    ),
                  ),
                ],
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
