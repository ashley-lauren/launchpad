import 'package:flutter/material.dart';

import '../../models/launchpad_models.dart';
import '../../services/launchpad_controller.dart';
import '../theme.dart';
import '../widgets/robot_mascot.dart';

class ClassroomDisplayScreen extends StatelessWidget {
  const ClassroomDisplayScreen({super.key, required this.controller});

  final LaunchpadController controller;

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
    final phaseDisplay = currentPhase?.display ?? const {};
    final displaySettings = lesson?.displaySettings;
    final showTeamMap = phaseDisplay['showTeamMap'] as bool? ??
        displaySettings?.showTeamMap ??
        true;
    final showLeaderboard = phaseDisplay['showLeaderboard'] as bool? ??
        displaySettings?.showLeaderboard ??
        true;
    final sortedTeams = [...state.teams]
      ..sort((a, b) => b.points.compareTo(a.points));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 900;
          final phaseType = currentPhase?.type.toLowerCase() ?? 'warmup';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: switch (phaseType) {
              'instruction' => _InstructionPhaseDisplay(
                  controller: controller,
                  phase: currentPhase,
                  agenda: agenda,
                  currentAgendaIndex: currentAgendaIndex,
                ),
              'warmup' => _WarmupPhaseDisplay(
                  controller: controller,
                  phase: currentPhase,
                  prompt: prompt,
                  agenda: agenda,
                  currentAgendaIndex: currentAgendaIndex,
                  wide: wide,
                  showTeamMap: showTeamMap,
                  showLeaderboard: showLeaderboard,
                  teams: state.teams,
                  sortedTeams: sortedTeams,
                ),
              _ => _GenericPhaseDisplay(
                  controller: controller,
                  phase: currentPhase,
                  agenda: agenda,
                  currentAgendaIndex: currentAgendaIndex,
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
    required this.wide,
    required this.showTeamMap,
    required this.showLeaderboard,
    required this.teams,
    required this.sortedTeams,
  });

  final LaunchpadController controller;
  final LessonPhase? phase;
  final String prompt;
  final List<AgendaItem> agenda;
  final int? currentAgendaIndex;
  final bool wide;
  final bool showTeamMap;
  final bool showLeaderboard;
  final List<Team> teams;
  final List<Team> sortedTeams;

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
        ),
        const SizedBox(height: 18),
        if (!showTeamMap && !showLeaderboard)
          const SizedBox.shrink()
        else if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showTeamMap)
                Expanded(
                  flex: 5,
                  child: _TeamGrid(teams: teams),
                ),
              if (showTeamMap && showLeaderboard) const SizedBox(width: 18),
              if (showLeaderboard)
                Expanded(
                  flex: 4,
                  child: _Standings(teams: sortedTeams),
                ),
            ],
          )
        else ...[
          if (showTeamMap) _TeamGrid(teams: teams),
          if (showTeamMap && showLeaderboard) const SizedBox(height: 18),
          if (showLeaderboard) _Standings(teams: sortedTeams),
        ],
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
  });

  final LaunchpadController controller;
  final String prompt;
  final List<AgendaItem> agenda;
  final List<String> keyActions;
  final int? currentAgendaIndex;

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
                        for (final action in keyActions)
                          _Expectation(action),
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
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (var i = 0; i < agenda.length; i++) ...[
                        _AgendaFlowItem(
                          label: agenda[i].title,
                          durationLabel: '~ ${agenda[i].durationMinutes} min',
                          selected: i == currentAgendaIndex,
                        ),
                        if (i < agenda.length - 1)
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF7EE787),
                            size: 24,
                          ),
                      ],
                    ],
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

class _InstructionPhaseDisplay extends StatelessWidget {
  const _InstructionPhaseDisplay({
    required this.controller,
    required this.phase,
    required this.agenda,
    required this.currentAgendaIndex,
  });

  final LaunchpadController controller;
  final LessonPhase? phase;
  final List<AgendaItem> agenda;
  final int? currentAgendaIndex;

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
  });

  final LaunchpadController controller;
  final LessonPhase? phase;
  final List<AgendaItem> agenda;
  final int? currentAgendaIndex;

  @override
  Widget build(BuildContext context) {
    final currentPhase = phase;
    final prompt = currentPhase?.prompt ?? '';
    final instructions = currentPhase?.instructions ?? const <String>[];
    final keyActions = currentPhase?.keyActions ?? const <String>[];

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
                  if (keyActions.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(
                      'Key Actions',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final action in keyActions)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '• $action',
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
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < agenda.length; i++) ...[
              _AgendaFlowItem(
                label: agenda[i].title,
                durationLabel: '~ ${agenda[i].durationMinutes} min',
                selected: i == currentAgendaIndex,
              ),
              if (i < agenda.length - 1)
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF7EE787),
                  size: 24,
                ),
            ],
          ],
        ),
      ],
    );
  }
}

class _AgendaFlowItem extends StatelessWidget {
  const _AgendaFlowItem({
    required this.label,
    required this.durationLabel,
    this.selected = false,
  });

  final String label;
  final String durationLabel;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF7EE787).withValues(alpha: 0.12)
            : const Color(0xFF7EE787).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF7EE787).withValues(
            alpha: selected ? 0.9 : 0.45,
          ),
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFF7EE787).withValues(alpha: 0.16),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  color: Color(0xFFE6EDF3),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              durationLabel,
              style: const TextStyle(
                color: Color(0xFF7EE787),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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

class _TeamGrid extends StatelessWidget {
  const _TeamGrid({required this.teams});

  final List<Team> teams;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 400),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Team Map',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.55,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: teams.map((team) {
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: teamAccentColor(team).withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                    ),
                    color: teamAccentColor(team).withValues(alpha: 0.04),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            team.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            team.members
                                .asMap()
                                .entries
                                .map((e) => e.value)
                                .join('\n'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8B949E),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Standings extends StatelessWidget {
  const _Standings({required this.teams});

  final List<Team> teams;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 400),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Leaderboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              for (final team in teams)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
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
                        '${team.points}',
                        style: TextStyle(color: teamAccentColor(team)),
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
