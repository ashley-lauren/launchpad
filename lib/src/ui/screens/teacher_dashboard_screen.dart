// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'package:flutter/material.dart';

import '../../models/launchpad_models.dart';
import '../../services/launchpad_controller.dart';
import '../theme.dart';
import '../widgets/lesson_json_editor.dart';
import '../widgets/table_layout_builder.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({
    super.key,
    required this.controller,
    this.isAdmin = false,
  });

  final LaunchpadController controller;
  final bool isAdmin;

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  late final TextEditingController _promptController;
  late final TextEditingController _agendaController;

  @override
  void initState() {
    super.initState();
    final warmup = widget.controller.state.warmup;
    _promptController = TextEditingController(text: warmup.prompt);
    _agendaController = TextEditingController(
      text: warmup.agenda.map((item) => item.title).join('\n'),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _agendaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1120;
          final left = Column(
            children: [
              if (!widget.isAdmin)
                ...[
                  _CurrentActivityPanel(controller: widget.controller),
                  const SizedBox(height: 18),
                ],
              if (widget.isAdmin)
                LessonJsonEditor(controller: widget.controller)
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Warmup Config',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _promptController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(labelText: 'Today\'s prompt'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _agendaController,
                          minLines: 4,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: 'Agenda, one item per line',
                          ),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => widget.controller.updateWarmup(
                              prompt: _promptController.text.trim(),
                              agenda: _agendaController.text.split('\n'),
                            ),
                            child: const Text('Save warm-up'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _TimerControls(controller: widget.controller),
              ],
            ],
          );
          final right = Column(
            children: [
              if (!widget.isAdmin) ...[
                _Submissions(submissions: state.submissions, teams: state.teams),
                const SizedBox(height: 18),
              ],
              if (widget.isAdmin)
                TableLayoutBuilder(controller: widget.controller)
              else
                _TeamsPanel(controller: widget.controller),
              const SizedBox(height: 18),
            ],
          );
          if (!wide) {
            return Column(children: [left, const SizedBox(height: 18), right]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: left),
              const SizedBox(width: 18),
              Expanded(child: right),
            ],
          );
        },
      ),
    );
  }
}

class _CurrentActivityPanel extends StatefulWidget {
  const _CurrentActivityPanel({required this.controller});

  final LaunchpadController controller;

  @override
  State<_CurrentActivityPanel> createState() => _CurrentActivityPanelState();
}

class _CurrentActivityPanelState extends State<_CurrentActivityPanel> {
  late final TextEditingController _activityController;

  @override
  void initState() {
    super.initState();
    _activityController = TextEditingController(
      text: widget.controller.currentActivity,
    );
  }

  @override
  void didUpdateWidget(covariant _CurrentActivityPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.currentActivity !=
        widget.controller.currentActivity) {
      _activityController.text = widget.controller.currentActivity;
    }
  }

  @override
  void dispose() {
    _activityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _activityController,
              decoration: const InputDecoration(labelText: 'Activity'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.controller.classroomStateStatusText,
                    style: const TextStyle(color: Color(0xFF8B949E)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    await widget.controller.updateCurrentActivity(
                      _activityController.text,
                    );
                  },
                  child: const Text('Update Activity'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Live class controls',
                    style: TextStyle(color: Color(0xFF8B949E)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (widget.controller.isLive) {
                      await widget.controller.endLiveClass();
                    } else {
                      await widget.controller.startLiveClass();
                    }
                  },
                  child: Text(widget.controller.isLive
                      ? 'End Live Class'
                      : 'Start Live Class'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerControls extends StatelessWidget {
  const _TimerControls({required this.controller});

  final LaunchpadController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Timer Control',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
            TextButton(
              onPressed: controller.resetTimer,
              child: const Text('Reset'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: controller.timerRunning
                  ? controller.pauseTimer
                  : controller.timerPaused
                      ? controller.resumeTimer
                      : controller.startTimer,
              child: Text(
                controller.timerRunning
                    ? 'Pause'
                    : controller.timerPaused
                        ? 'Resume'
                        : 'Start',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Submissions extends StatelessWidget {
  const _Submissions({required this.submissions, required this.teams});

  final List<Submission> submissions;
  final List<Team> teams;

  @override
  Widget build(BuildContext context) {
    final teamById = {
      for (final team in teams) team.id: 'Table ${team.tableNumber}'
    };
    return Card(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Submissions Stream',
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
                              '${teamById[submission.teamId]} / ${submission.confidence} confidence',
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

class _TeamsPanel extends StatefulWidget {
  const _TeamsPanel({required this.controller});

  final LaunchpadController controller;

  @override
  State<_TeamsPanel> createState() => _TeamsPanelState();
}

class _TeamsPanelState extends State<_TeamsPanel> {
  late Map<String, TextEditingController> _nameControllers;
  late Map<String, TextEditingController> _membersControllers;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameControllers = {};
    _membersControllers = {};
    for (final team in widget.controller.state.teams) {
      _nameControllers[team.id] = TextEditingController(text: team.name);
      _membersControllers[team.id] =
          TextEditingController(text: team.members.join('\n'));
    }
  }

  @override
  void dispose() {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    for (final controller in _membersControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Table Assignments',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              for (final team in widget.controller.state.teams)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10161F),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.72),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(
                              width: 260,
                              child: TextField(
                                controller: _nameControllers[team.id],
                                readOnly: true,
                                decoration: const InputDecoration(
                                  hintText: 'Table number',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _membersControllers[team.id],
                          maxLines: 3,
                          minLines: 2,
                          decoration: const InputDecoration(
                            hintText:
                                'Student names (one per line)\nE.g.: Alex\nJordan',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              widget.controller.updateTeam(
                                teamId: team.id,
                                name: 'Table ${team.tableNumber}',
                                members: _membersControllers[team.id]!
                                    .text
                                    .split('\n')
                                    .map((m) => m.trim())
                                    .where((m) => m.isNotEmpty)
                                    .toList(),
                              );
                            },
                            child: const Text('Save members'),
                          ),
                        ),
                      ],
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

