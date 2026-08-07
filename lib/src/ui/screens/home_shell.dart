import 'package:flutter/material.dart';

import '../../models/launchpad_role.dart';
import '../../services/launchpad_controller.dart';
import '../widgets/status_pill.dart';
import 'classroom_display_screen.dart';
import 'teacher_dashboard_screen.dart';
import 'team_submission_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller, required this.role});

  final LaunchpadController controller;
  final LaunchpadRole role;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
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

    final roleLabel = switch (widget.role) {
      LaunchpadRole.student => 'Student',
      LaunchpadRole.teacher => 'Teacher',
      LaunchpadRole.admin => 'Admin',
    };

    final statusLabel = switch (widget.role) {
      LaunchpadRole.student => widget.controller.liveStatusLabel,
      LaunchpadRole.teacher => widget.controller.isLive ? 'Live' : 'Not Live',
      LaunchpadRole.admin => 'Connected',
    };

    final statusColor = switch (widget.role) {
      LaunchpadRole.student => widget.controller.liveStatusColor,
      LaunchpadRole.teacher => widget.controller.isLive
          ? const Color(0xFF7EE787)
          : const Color(0xFF8B949E),
      LaunchpadRole.admin => const Color(0xFF79C0FF),
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: Row(
          children: [
            Text(
              'Launchpad · $roleLabel',
              style: const TextStyle(fontWeight: FontWeight.w800),
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
            child: StatusPill(
              label: statusLabel,
              color: statusColor,
              onTap: widget.role == LaunchpadRole.student &&
                      widget.controller.canToggleFollow
                  ? widget.controller.toggleFollowClass
                  : null,
            ),
          ),
        ],
        bottom: widget.role == LaunchpadRole.student
            ? const TabBar(
                tabs: [
                  Tab(text: 'Class'),
                  Tab(text: 'Submit'),
                ],
              )
            : null,
      ),
      body: _buildBody(),
      floatingActionButton: widget.role == LaunchpadRole.teacher
          ? Stack(
              children: [
                Positioned(
                  bottom: 0,
                  right: 64,
                  child: FloatingActionButton.small(
                    onPressed: () {
                      if (widget.controller.timerRunning) {
                        widget.controller.pauseTimer();
                      } else if (widget.controller.timerPaused) {
                        widget.controller.resumeTimer();
                      } else {
                        widget.controller.startTimer();
                      }
                    },
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    foregroundColor: Colors.black87,
                    child: Icon(
                      widget.controller.timerRunning
                          ? Icons.pause
                          : widget.controller.timerPaused
                              ? Icons.play_arrow
                              : Icons.play_arrow,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 64,
                  right: 0,
                  child: FloatingActionButton.small(
                    onPressed: widget.controller.state.currentPhaseIndex <= 0
                        ? null
                        : widget.controller.previousPhase,
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
                    onPressed:
                        (widget.controller.state.activeLesson?.phases.isEmpty ??
                                    true) ||
                                widget.controller.state.currentPhaseIndex >=
                                    (widget.controller.state.activeLesson
                                                ?.phases.length ??
                                            0) -
                                        1
                            ? null
                            : widget.controller.nextPhase,
                    backgroundColor:
                        (widget.controller.state.activeLesson?.phases.isEmpty ??
                                    true) ||
                                widget.controller.state.currentPhaseIndex >=
                                    (widget.controller.state.activeLesson
                                                ?.phases.length ??
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
    );
  }

  Widget _buildBody() {
    switch (widget.role) {
      case LaunchpadRole.student:
        return _StudentBody(controller: widget.controller);
      case LaunchpadRole.teacher:
        return ClassroomDisplayScreen(
          controller: widget.controller,
          showTeacherControls: true,
        );
      case LaunchpadRole.admin:
        return TeacherDashboardScreen(controller: widget.controller);
    }
  }
}

class _StudentBody extends StatelessWidget {
  const _StudentBody({required this.controller});

  final LaunchpadController controller;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Class'),
              Tab(text: 'Submit'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ClassroomDisplayScreen(
                  controller: controller,
                  showTeacherControls: false,
                ),
                TeamSubmissionScreen(controller: controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
