import 'package:flutter/material.dart';

import '../../models/launchpad_models.dart';
import '../../services/launchpad_controller.dart';
import '../theme.dart';
import '../widgets/launchpad_phase_flow.dart';
import '../widgets/robot_mascot.dart';

class ClassroomDisplayScreen extends StatelessWidget {
  const ClassroomDisplayScreen({
    super.key,
    required this.controller,
    this.showTeacherControls = false,
  });

  final LaunchpadController controller;
  final bool showTeacherControls;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final lesson = state.activeLesson;
    final currentPhase = state.currentPhase;
    final currentAgendaIndex = lesson == null || lesson.phases.isEmpty
        ? null
        : state.currentPhaseIndex;
    final agenda = lesson == null
        ? state.warmup.agenda
        : lesson.phases
            .map(
              (phase) => AgendaItem(
                title: phase.title,
                durationMinutes: (phase.durationSeconds / 60).ceil(),
              ),
            )
            .toList();
    final prompt = currentPhase == null
        ? state.warmup.prompt
        : currentPhase.prompt.isNotEmpty
            ? currentPhase.prompt
            : currentPhase.title;
    final displayPrompt = controller.currentActivity.isNotEmpty
        ? controller.currentActivity
        : prompt;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final phaseType = currentPhase?.type.toLowerCase() ?? 'warmup';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: switch (phaseType) {
              'instruction' => _InstructionPhaseDisplay(
                  controller: controller,
                  phase: currentPhase,
                  agenda: agenda,
                  currentAgendaIndex: currentAgendaIndex,
                  showTeacherControls: showTeacherControls,
                ),
              'warmup' => _WarmupPhaseDisplay(
                  controller: controller,
                  phase: currentPhase,
                  prompt: displayPrompt,
                  agenda: agenda,
                  currentAgendaIndex: currentAgendaIndex,
                  teams: state.teams,
                  showTeacherControls: showTeacherControls,
                ),
              _ => _GenericPhaseDisplay(
                  controller: controller,
                  phase: currentPhase,
                  agenda: agenda,
                  currentAgendaIndex: currentAgendaIndex,
                  showTeacherControls: showTeacherControls,
                ),
            },
          );
        },
      ),
    );
  }
}

class _WarmupPhaseDisplay extends StatelessWidget {
  const _WarmupPhaseDisplay({
    required this.controller,
    required this.phase,
    required this.prompt,
    required this.agenda,
    required this.currentAgendaIndex,
    required this.teams,
    required this.showTeacherControls,
  });

  final LaunchpadController controller;
  final LessonPhase? phase;
  final String prompt;
  final List<AgendaItem> agenda;
  final int? currentAgendaIndex;
  final List<Team> teams;
  final bool showTeacherControls;

  @override
  Widget build(BuildContext context) {
    final keyActions = phase?.keyActions.isNotEmpty == true
        ? phase!.keyActions
        : const [
            'Discuss with your team',
            'Submit one team answer',
            'Be ready to explain your reasoning',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroPanel(
          controller: controller,
          prompt: prompt,
          agenda: agenda,
          keyActions: keyActions,
          currentAgendaIndex: currentAgendaIndex,
          showTeacherControls: showTeacherControls,
        ),
        const SizedBox(height: 18),
        _TableAssignments(teams: teams),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.controller,
    required this.prompt,
    required this.agenda,
    required this.keyActions,
    required this.currentAgendaIndex,
    required this.showTeacherControls,
  });

  final LaunchpadController controller;
  final String prompt;
  final List<AgendaItem> agenda;
  final List<String> keyActions;
  final int? currentAgendaIndex;
  final bool showTeacherControls;

  @override
  Widget build(BuildContext context) {
    final minutes = (controller.secondsRemaining ~/ 60).toString().padLeft(
          2,
          '0',
        );
    final seconds = (controller.secondsRemaining % 60).toString().padLeft(
          2,
          '0',
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showTeacherControls)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Runtime controls are available in Teacher mode',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  Text(
                    '$minutes:$seconds',
                    style: const TextStyle(
                      color: Color(0xFF00D7FF),
                      fontSize: 72,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    prompt,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (keyActions.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final action in keyActions) _Expectation(action),
                      ],
                    ),
                    const SizedBox(height: 48),
                  ],
                  Text(
                    "Today's Agenda",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LaunchpadPhaseFlow(
                    items: agenda,
                    selectedIndex: currentAgendaIndex,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const RobotMascot(),
          ],
        ),
      ),
    );
  }
}

class _TableAssignments extends StatelessWidget {
  const _TableAssignments({required this.teams});

  final List<Team> teams;

  @override
  Widget build(BuildContext context) {
    final sortedTables = [...teams]
      ..sort((a, b) => a.tableNumber.compareTo(b.tableNumber));

    if (sortedTables.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Table Assignments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.25,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: sortedTables.map((team) {
                final accent = teamAccentColor(team).withValues(alpha: 0.35);
                final visibleMembers = team.members.take(4).toList();
                return SizedBox(
                  height: 150,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accent),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Table ${team.tableNumber}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (visibleMembers.isEmpty)
                            const Text(
                              'Students will be added here.',
                              style: TextStyle(
                                color: Color(0xFF8B949E),
                                fontSize: 11,
                              ),
                            )
                          else
                            ...visibleMembers.map(
                              (member) => Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  member,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFE6EDF3),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionPhaseDisplay extends StatelessWidget {
  const _InstructionPhaseDisplay({
    required this.controller,
    required this.phase,
    required this.agenda,
    required this.currentAgendaIndex,
    required this.showTeacherControls,
  });

  final LaunchpadController controller;
  final LessonPhase? phase;
  final List<AgendaItem> agenda;
  final int? currentAgendaIndex;
  final bool showTeacherControls;

  @override
  Widget build(BuildContext context) {
    final currentPhase = phase;
    final keyIdeas = currentPhase?.keyIdeas ?? const <String>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DisplayTimer(controller: controller),
                  const SizedBox(height: 42),
                  Text(
                    currentPhase?.title ?? 'Instruction',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Key Ideas',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (keyIdeas.isEmpty)
                    const Text(
                      'Focus on the key concepts being introduced.',
                      style: TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 22,
                        height: 1.35,
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final idea in keyIdeas)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              '• $idea',
                              style: const TextStyle(
                                color: Color(0xFF8B949E),
                              ),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 40),
                  _AgendaRow(
                    agenda: agenda,
                    currentAgendaIndex: currentAgendaIndex,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const RobotMascot(),
          ],
        ),
      ),
    );
  }
}

class _GenericPhaseDisplay extends StatelessWidget {
  const _GenericPhaseDisplay({
    required this.controller,
    required this.phase,
    required this.agenda,
    required this.currentAgendaIndex,
    required this.showTeacherControls,
  });

  final LaunchpadController controller;
  final LessonPhase? phase;
  final List<AgendaItem> agenda;
  final int? currentAgendaIndex;
  final bool showTeacherControls;

  @override
  Widget build(BuildContext context) {
    final currentPhase = phase;
    final prompt = currentPhase?.prompt ?? '';
    final instructions = currentPhase?.instructions ?? const <String>[];
    final phaseType = currentPhase?.type.toLowerCase() ?? '';
    final isConceptualPhase = phaseType == 'discussion';

    // Show Key Ideas for conceptual phases (discussion), Key Actions for activity phases
    final guidanceItems = isConceptualPhase
        ? (currentPhase?.keyIdeas ?? const <String>[])
        : (currentPhase?.keyActions ?? const <String>[]);
    final guidanceLabel = isConceptualPhase ? 'Key Ideas' : 'Key Actions';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DisplayTimer(controller: controller),
                  const SizedBox(height: 42),
                  Text(
                    currentPhase?.title ?? 'Lesson Phase',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  if (prompt.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      prompt,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ],
                  if (instructions.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final instruction in instructions)
                          _Expectation(instruction),
                      ],
                    ),
                  ],
                  if (guidanceItems.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(
                      guidanceLabel,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final item in guidanceItems)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '• $item',
                              style: const TextStyle(
                                color: Color(0xFF8B949E),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 40),
                  _AgendaRow(
                    agenda: agenda,
                    currentAgendaIndex: currentAgendaIndex,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const RobotMascot(),
          ],
        ),
      ),
    );
  }
}

class _DisplayTimer extends StatelessWidget {
  const _DisplayTimer({required this.controller});

  final LaunchpadController controller;

  @override
  Widget build(BuildContext context) {
    final minutes = (controller.secondsRemaining ~/ 60).toString().padLeft(
          2,
          '0',
        );
    final seconds = (controller.secondsRemaining % 60).toString().padLeft(
          2,
          '0',
        );
    return Text(
      '$minutes:$seconds',
      style: const TextStyle(
        color: Color(0xFF00D7FF),
        fontSize: 72,
        height: 1,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    required this.agenda,
    required this.currentAgendaIndex,
  });

  final List<AgendaItem> agenda;
  final int? currentAgendaIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Agenda",
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        LaunchpadPhaseFlow(
          items: agenda,
          selectedIndex: currentAgendaIndex,
        ),
      ],
    );
  }
}

class _Expectation extends StatelessWidget {
  const _Expectation(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF79C0FF).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF79C0FF).withValues(alpha: .35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }
}
