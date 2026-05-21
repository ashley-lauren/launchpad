import 'package:flutter/material.dart';

import '../../models/launchpad_models.dart';
import '../../services/launchpad_controller.dart';
import '../theme.dart';

class TeamSubmissionScreen extends StatefulWidget {
  const TeamSubmissionScreen({super.key, required this.controller});

  final LaunchpadController controller;

  @override
  State<TeamSubmissionScreen> createState() => _TeamSubmissionScreenState();
}

class _TeamSubmissionScreenState extends State<TeamSubmissionScreen> {
  final _answerController = TextEditingController();
  String? _teamId;
  String _confidence = 'Medium';
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _teamId = widget.controller.state.teams.isEmpty
        ? null
        : widget.controller.state.teams.first.id;
    _answerController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    final selectedTeam = _selectedTeam(state);
    final currentPhase = state.currentPhase;
    final submission = currentPhase?.submission;
    final prompt = currentPhase?.prompt.isNotEmpty == true
        ? currentPhase!.prompt
        : state.warmup.prompt;

    if (submission == null || !submission.enabled) {
      return const _PhaseSubmissionPlaceholder(
        message: 'No team submission needed for this phase.',
      );
    }
    if (submission.mode == 'individual') {
      return const _PhaseSubmissionPlaceholder(
        message: 'Individual reflection coming soon.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _submitted
                    ? _Confirmation(
                        onAnother: () {
                          setState(() {
                            _submitted = false;
                            _answerController.clear();
                          });
                        },
                      )
                    : Column(
                        key: const ValueKey('form'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Submit Answer',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            prompt,
                            style: const TextStyle(color: Color(0xFF8B949E)),
                          ),
                          const SizedBox(height: 22),
                          if (state.teams.isEmpty) ...[
                            const _NoTeamsMessage(),
                            const SizedBox(height: 22),
                          ] else
                            Builder(builder: (context) {
                              final accent = teamAccentColor(selectedTeam!);
                              return DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: selectedTeam.id,
                                items: state.teams
                                    .map(
                                      (team) => DropdownMenuItem(
                                        value: team.id,
                                        child: Text(
                                          team.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _teamId = value),
                                decoration: InputDecoration(
                                  labelText: 'Team',
                                  filled: true,
                                  fillColor: accent.withValues(alpha: 0.08),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: accent.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: accent.withValues(alpha: 0.65),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _answerController,
                            minLines: 5,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              labelText: 'Warm-up answer',
                              hintText:
                                  'Explain the strategy your team would try first...',
                            ),
                          ),
                          if (submission.confidenceSelector) ...[
                            const SizedBox(height: 14),
                            const Text(
                              'Confidence',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<String>(
                              showSelectedIcon: false,
                              style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return const Color(0xFF79C0FF)
                                        .withValues(alpha: 0.06);
                                  }
                                  return const Color(0xFF0D1117);
                                }),
                                foregroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return const Color(0xFFE6EDF3);
                                  }
                                  return const Color(0xFF8B949E);
                                }),
                                side:
                                    WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return BorderSide(
                                      color: const Color(0xFF79C0FF)
                                          .withValues(alpha: 0.35),
                                    );
                                  }
                                  return const BorderSide(
                                    color: Color(0xFF30363D),
                                  );
                                }),
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                textStyle: WidgetStateProperty.all(
                                  const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              segments: const [
                                ButtonSegment(
                                  value: 'Low',
                                  label: Text('Low'),
                                ),
                                ButtonSegment(
                                  value: 'Medium',
                                  label: Text('Medium'),
                                ),
                                ButtonSegment(
                                  value: 'High',
                                  label: Text('High'),
                                ),
                              ],
                              selected: {_confidence},
                              onSelectionChanged: (value) =>
                                  setState(() => _confidence = value.first),
                            ),
                          ],
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: selectedTeam == null ||
                                      _answerController.text.trim().isEmpty
                                  ? null
                                  : () async {
                                      await widget.controller.submitAnswer(
                                        teamId: selectedTeam.id,
                                        answer: _answerController.text.trim(),
                                        confidence: submission
                                                .confidenceSelector
                                            ? _confidence
                                            : 'Not collected',
                                      );
                                      if (mounted) {
                                        setState(() => _submitted = true);
                                      }
                                    },
                              child: const Text('Submit team answer'),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Team? _selectedTeam(LaunchpadState state) {
    if (state.teams.isEmpty) return null;
    for (final team in state.teams) {
      if (team.id == _teamId) return team;
    }
    return state.teams.first;
  }
}

class _PhaseSubmissionPlaceholder extends StatelessWidget {
  const _PhaseSubmissionPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Text(
                message,
                style: const TextStyle(color: Color(0xFF8B949E)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoTeamsMessage extends StatelessWidget {
  const _NoTeamsMessage();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFF0D1117),
        borderRadius: BorderRadius.all(Radius.circular(12)),
        border: Border.fromBorderSide(BorderSide(color: Color(0xFF30363D))),
      ),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Text(
          'No teams are available yet. Add teams in the Teacher tab before submitting an answer.',
          style: TextStyle(color: Color(0xFF8B949E)),
        ),
      ),
    );
  }
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({required this.onAnother});

  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('confirmation'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Answer submitted',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your thinking is saved locally and queued for sync. Nice reasoning sprint.',
        ),
        const SizedBox(height: 22),
        TextButton(
          onPressed: onAnother,
          child: const Text('Submit another answer'),
        ),
      ],
    );
  }
}
