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
    final sortedTeams = [...state.teams]
      ..sort((a, b) => b.points.compareTo(a.points));
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroPanel(controller: controller, warmup: state.warmup),
                const SizedBox(height: 18),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _TeamGrid(teams: state.teams)),
                      const SizedBox(width: 18),
                      Expanded(flex: 4, child: _Standings(teams: sortedTeams)),
                    ],
                  )
                else ...[
                  _TeamGrid(teams: state.teams),
                  const SizedBox(height: 18),
                  _Standings(teams: sortedTeams),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.controller, required this.warmup});

  final LaunchpadController controller;
  final Warmup warmup;

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
                    warmup.prompt,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Expectation('Discuss with your team'),
                      _Expectation('Submit one team answer'),
                      _Expectation('Be ready to explain your reasoning'),
                    ],
                  ),
                  const SizedBox(height: 48),
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
                      for (var i = 0; i < warmup.agenda.length; i++) ...[
                        _AgendaFlowItem(
                          label: warmup.agenda[i],
                          durationLabel: '≈ 5 min',
                        ),
                        if (i < warmup.agenda.length - 1)
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

class _AgendaFlowItem extends StatelessWidget {
  const _AgendaFlowItem({required this.label, required this.durationLabel});

  final String label;
  final String durationLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF7EE787).withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF7EE787).withOpacity(0.45)),
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
        child: Text(label,
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false),
      ),
    );
  }
}

class _TeamGrid extends StatelessWidget {
  const _TeamGrid({required this.teams});

  final List<Team> teams;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                      color: teamAccentColor(team).withOpacity(0.45),
                      width: 1.5,
                    ),
                  ),
                  color: teamAccentColor(team).withOpacity(0.04),
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
    );
  }
}

class _Standings extends StatelessWidget {
  const _Standings({required this.teams});

  final List<Team> teams;

  @override
  Widget build(BuildContext context) {
    return Card(
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
    );
  }
}
