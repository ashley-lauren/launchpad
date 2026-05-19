import 'package:flutter/material.dart';

import '../../models/launchpad_models.dart';
import '../../services/launchpad_controller.dart';
import '../theme.dart';
import '../widgets/status_pill.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key, required this.controller});

  final LaunchpadController controller;

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
    _agendaController = TextEditingController(text: warmup.agenda.join('\n'));
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
          final wide = constraints.maxWidth > 980;
          final left = Column(
            children: [
              _ClassSelector(
                classes: state.classes,
                selectedClass: state.launchClass,
                onClassSelected: widget.controller.selectClass,
              ),
              const SizedBox(height: 18),
              _WarmupEditor(
                promptController: _promptController,
                agendaController: _agendaController,
                onSave: () => widget.controller.updateWarmup(
                  prompt: _promptController.text.trim(),
                  agenda: _agendaController.text.split('\n'),
                ),
              ),
              const SizedBox(height: 18),
              _TimerControls(controller: widget.controller),
              const SizedBox(height: 18),
              const _AmbientSoon(),
            ],
          );
          final right = Column(
            children: [
              _Submissions(submissions: state.submissions, teams: state.teams),
              const SizedBox(height: 18),
              _PointsPanel(controller: widget.controller),
              const SizedBox(height: 18),
              _TeamsPanel(controller: widget.controller),
              const SizedBox(height: 18),
              _DemoPanel(controller: widget.controller),
            ],
          );
          if (!wide) {
            return Column(children: [left, const SizedBox(height: 18), right]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 18),
              Expanded(child: right),
            ],
          );
        },
      ),
    );
  }
}

class _ClassSelector extends StatelessWidget {
  const _ClassSelector({
    required this.classes,
    required this.selectedClass,
    required this.onClassSelected,
  });

  final List<LaunchClass> classes;
  final LaunchClass selectedClass;
  final ValueChanged<String> onClassSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Class Selectction',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedClass.id,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: classes
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onClassSelected(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WarmupEditor extends StatelessWidget {
  const _WarmupEditor({
    required this.promptController,
    required this.agendaController,
    required this.onSave,
  });

  final TextEditingController promptController;
  final TextEditingController agendaController;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
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
              controller: promptController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Today\'s prompt'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: agendaController,
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
                onPressed: onSave,
                child: const Text('Save warm-up'),
              ),
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
              onPressed: controller.startTimer,
              child: const Text('Start'),
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
    final teamById = {for (final team in teams) team.id: team.name};
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

class _PointsPanel extends StatelessWidget {
  const _PointsPanel({required this.controller});

  final LaunchpadController controller;

  @override
  Widget build(BuildContext context) {
    const reasons = [
      'Great reasoning',
      'Creative idea',
      'Strong collaboration',
      'Helpful mistake',
    ];
    final teams = controller.state.teams;
    return Card(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Points Quick-Add',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              for (final team in teams)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: teamAccentColor(team),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          team.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${team.points} pts',
                        style: TextStyle(color: teamAccentColor(team)),
                      ),
                    ],
                  ),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final reason in reasons)
                          OutlinedButton(
                            onPressed: () => controller.awardPoints(
                              teamId: team.id,
                              reason: reason,
                            ),
                            child: Text('+1 $reason'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
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
                'Teams',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              for (final team in widget.controller.state.teams)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: teamAccentColor(team),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _nameControllers[team.id],
                              decoration: InputDecoration(
                                hintText: 'Team name',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.check),
                                  onPressed: () {
                                    widget.controller.updateTeam(
                                      teamId: team.id,
                                      name: _nameControllers[team.id]!
                                          .text
                                          .trim(),
                                      members: _membersControllers[team.id]!
                                          .text
                                          .split('\n')
                                          .map((m) => m.trim())
                                          .where((m) => m.isNotEmpty)
                                          .toList(),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _membersControllers[team.id],
                        maxLines: 2,
                        minLines: 2,
                        decoration: const InputDecoration(
                          hintText:
                              'Student names (one per line)\nE.g.: Alex\nJordan',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoPanel extends StatelessWidget {
  const _DemoPanel({required this.controller});

  final LaunchpadController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(child: StatusPill(status: controller.syncStatus)),
            TextButton(
              onPressed: controller.resetDemoData,
              child: const Text('Reset Demo Data'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientSoon extends StatelessWidget {
  const _AmbientSoon();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Opacity(
          opacity: .55,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Ambient Mode',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              Chip(label: Text('coming soon')),
            ],
          ),
        ),
      ),
    );
  }
}
