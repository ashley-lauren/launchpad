import 'package:flutter/material.dart';

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
    _teamId = widget.controller.state.teams.first.id;
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
                            'submit.answer',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            state.warmup.prompt,
                            style: const TextStyle(color: Color(0xFF8B949E)),
                          ),
                          const SizedBox(height: 22),
                          Builder(builder: (context) {
                            final selectedTeam = state.teams.firstWhere(
                              (team) => team.id == _teamId,
                              orElse: () => state.teams.first,
                            );
                            final accent = teamAccentColor(selectedTeam);
                            return DropdownButtonFormField<String>(
                              value: _teamId,
                              items: state.teams
                                  .map(
                                    (team) => DropdownMenuItem(
                                      value: team.id,
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
                                          Expanded(child: Text(team.name)),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _teamId = value),
                              decoration: InputDecoration(
                                labelText: 'Team',
                                filled: true,
                                fillColor: accent.withOpacity(0.08),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: accent.withOpacity(0.35),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: accent.withOpacity(0.65),
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
                          const SizedBox(height: 14),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'Low', label: Text('Low')),
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
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _answerController.text.trim().isEmpty
                                  ? null
                                  : () async {
                                      await widget.controller.submitAnswer(
                                        teamId: _teamId!,
                                        answer: _answerController.text.trim(),
                                        confidence: _confidence,
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
          'answer.received',
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
