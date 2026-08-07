// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';

import '../../models/launchpad_models.dart';
import '../../services/launchpad_controller.dart';
import 'launchpad_phase_flow.dart';

class LessonJsonEditor extends StatefulWidget {
  const LessonJsonEditor({super.key, required this.controller});

  final LaunchpadController controller;

  @override
  State<LessonJsonEditor> createState() => _LessonJsonEditorState();
}

class _LessonJsonEditorState extends State<LessonJsonEditor> {
  final _editorController = TextEditingController();
  late final TextEditingController _titleController;
  late final TextEditingController _dateController;
  String? _statusMessage;
  bool _isValidating = false;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  bool _structuredMode = true;
  bool _updatingEditorText = false;
  Lesson? _lastValidLesson;
  Map<String, dynamic> _currentLessonJson = <String, dynamic>{};
  List<String> _validationErrors = const [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _dateController = TextEditingController();
    _editorController.addListener(_onEditorChanged);
    _loadCurrentLesson();
  }

  @override
  void didUpdateWidget(covariant LessonJsonEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldLessonId = oldWidget.controller.classroomState?.lessonId;
    final newLessonId = widget.controller.classroomState?.lessonId;
    final oldClassId = oldWidget.controller.classroomState?.classId;
    final newClassId = widget.controller.classroomState?.classId;
    if (oldLessonId != newLessonId || oldClassId != newClassId) {
      _loadCurrentLesson();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    _dateController.dispose();
    _editorController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLesson() async {
    final lessonId = widget.controller.classroomState?.lessonId;
    if (lessonId == null) {
      _resetEditorToSkeleton();
      return;
    }

    try {
      final lesson = await widget.controller.loadLessonEditorContent(lessonId: lessonId);
      if (!mounted) return;
      _applyLessonJson(
        _normalizeLessonJson(lesson.toJson()),
        updateText: true,
        markDirty: false,
        statusMessage: 'Loaded lesson JSON',
        validate: true,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Could not load lesson JSON: $error';
      });
    }
  }

  void _resetEditorToSkeleton() {
    final selectedClass = widget.controller.selectedPersistedClass;
    final selectedLesson = widget.controller.selectedPersistedLesson;
    final title = selectedLesson?.title.trim().isNotEmpty == true ? selectedLesson!.title.trim() : '';
    final date = selectedLesson?.lessonDate != null
        ? selectedLesson!.lessonDate!.toIso8601String()
        : DateTime.now().toIso8601String().split('T').first;
    _applyLessonJson(
      _lessonSkeleton(
        selectedClass: selectedClass,
        title: title,
        date: date,
      ),
      updateText: true,
      markDirty: false,
      statusMessage: 'Ready to create a lesson',
      validate: true,
    );
  }

  void _onEditorChanged() {
    if (_updatingEditorText) {
      _updatingEditorText = false;
      return;
    }
    if (_editorController.text.isEmpty) {
      return;
    }
    _hasUnsavedChanges = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _validateCurrentJson();
    });
  }

  Future<void> _validateCurrentJson() async {
    if (_isValidating) return;
    final raw = _editorController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _statusMessage = 'Enter JSON to validate.';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _statusMessage = 'Validating…';
    });

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Lesson JSON must be an object.');
      }
      _applyLessonJson(
        _normalizeLessonJson(decoded),
        updateText: false,
        markDirty: true,
        statusMessage: 'Valid lesson JSON',
        validate: true,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isValidating = false;
        _validationErrors = ['Invalid JSON: $error'];
        _statusMessage = 'Invalid JSON: $error';
      });
    }
  }

  List<String> _validateLessonStructure(Map<String, dynamic> lessonJson) {
    final errors = <String>[];
    final lesson = Lesson.fromJson(lessonJson);
    if (lesson.lessonInfo.title.trim().isEmpty) {
      errors.add('Lesson title is required.');
    }
    if (lesson.phases.isEmpty) {
      errors.add('At least one phase is required.');
    }
    final seenIds = <String>{};
    for (var index = 0; index < lesson.phases.length; index++) {
      final phase = lesson.phases[index];
      if (phase.id.trim().isEmpty) {
        errors.add('Phase ${index + 1} is missing an id.');
      }
      if (seenIds.contains(phase.id)) {
        errors.add('Duplicate phase id: ${phase.id}');
      } else {
        seenIds.add(phase.id);
      }
      if (phase.title.trim().isEmpty) {
        errors.add('Phase ${phase.id} is missing a title.');
      }
      if (phase.durationSeconds <= 0) {
        errors.add('Phase ${phase.id} must have a positive duration.');
      }
    }
    return errors;
  }

  void _applyLessonJson(
    Map<String, dynamic> lessonJson, {
    required bool updateText,
    required bool markDirty,
    required String statusMessage,
    required bool validate,
  }) {
    final normalizedJson = _normalizeLessonJson(lessonJson);
    final validationErrors = validate ? _validateLessonStructure(normalizedJson) : const <String>[];
    final lesson = Lesson.fromJson(normalizedJson);
    if (!mounted) return;
    setState(() {
      _currentLessonJson = normalizedJson;
      _lastValidLesson = lesson;
      _validationErrors = validationErrors;
      _hasUnsavedChanges = markDirty;
      _isValidating = false;
      _statusMessage = validationErrors.isEmpty ? statusMessage : '$statusMessage (${validationErrors.join('; ')})';
      _syncStructuredFieldControllers(normalizedJson['lessonInfo']);
      if (updateText) {
        _updatingEditorText = true;
        _editorController.text = const JsonEncoder.withIndent('  ').convert(normalizedJson);
      }
    });
  }

  Map<String, dynamic> _normalizeLessonJson(Map<String, dynamic> lessonJson) {
    final normalized = Map<String, dynamic>.from(lessonJson);
    normalized['lessonInfo'] = _normalizeLessonInfo(normalized['lessonInfo']);
    normalized['phases'] = _normalizePhases(normalized['phases']);
    if (!normalized.containsKey('standards')) normalized['standards'] = <Map<String, dynamic>>[];
    if (!normalized.containsKey('learningObjectives')) normalized['learningObjectives'] = <String>[];
    if (!normalized.containsKey('successCriteria')) normalized['successCriteria'] = <String>[];
    if (!normalized.containsKey('vocabulary')) normalized['vocabulary'] = <String>[];
    if (!normalized.containsKey('materials')) normalized['materials'] = <String>[];
    if (!normalized.containsKey('differentiation')) normalized['differentiation'] = <String, dynamic>{};
    if (!normalized.containsKey('teacherMoves')) normalized['teacherMoves'] = <String, dynamic>{};
    if (!normalized.containsKey('displaySettings')) normalized.remove('displaySettings');
    if (!normalized.containsKey('pointRewards')) normalized.remove('pointRewards');
    if (!normalized.containsKey('phases')) normalized['phases'] = <Map<String, dynamic>>[];
    return normalized;
  }

  Map<String, dynamic> _normalizeLessonInfo(Object? infoValue) {
    final source = infoValue is Map ? Map<String, dynamic>.from(infoValue) : <String, dynamic>{};
    final selectedClass = widget.controller.selectedPersistedClass;
    final course = (source['course']?.toString() ?? '').trim().isNotEmpty
        ? source['course'].toString().trim()
        : (selectedClass?.courseName.trim().isNotEmpty == true ? selectedClass!.courseName.trim() : '');
    final period = (source['period']?.toString() ?? '').trim().isNotEmpty
        ? source['period'].toString().trim()
        : (selectedClass?.period.trim().isNotEmpty == true ? selectedClass!.period.trim() : '');
    final title = source['title']?.toString() ?? '';
    final date = source['date']?.toString() ?? '';
    return {
      'title': title,
      'course': course,
      'period': period,
      'date': date,
    };
  }

  List<Map<String, dynamic>> _normalizePhases(Object? phasesValue) {
    if (phasesValue is! List) return <Map<String, dynamic>>[];
    return phasesValue.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<void> _formatJson() async {
    final raw = _editorController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _statusMessage = 'Nothing to format.';
      });
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      final formatted = const JsonEncoder.withIndent('  ').convert(decoded);
      _updatingEditorText = true;
      _editorController.text = formatted;
      _hasUnsavedChanges = true;
      setState(() {
        _statusMessage = 'Formatted JSON';
      });
    } catch (error) {
      setState(() {
        _statusMessage = 'Format failed: $error';
      });
    }
  }

  Future<void> _importJson() async {
    final input = html.FileUploadInputElement()..accept = '.json,application/json';
    input.click();
    await input.onChange.first;
    final file = input.files?.isEmpty == false ? input.files!.first : null;
    if (file == null) return;

    try {
      final raw = await _readFileAsText(file);
      _updatingEditorText = true;
      _editorController.text = raw;
      _hasUnsavedChanges = true;
      setState(() {
        _statusMessage = 'Imported lesson JSON';
      });
      unawaited(_validateCurrentJson());
    } catch (error) {
      setState(() {
        _statusMessage = 'Import failed: $error';
      });
    }
  }

  Future<String> _readFileAsText(html.File file) {
    final completer = Completer<String>();
    final reader = html.FileReader();
    reader.onLoad.first.then((_) {
      completer.complete(reader.result?.toString() ?? '');
    });
    reader.onError.first.then((_) {
      completer.completeError('The selected file could not be read.');
    });
    reader.readAsText(file);
    return completer.future;
  }

  Future<void> _saveLesson() async {
    final raw = _editorController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _statusMessage = 'Nothing to save.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _statusMessage = 'Saving lesson…';
    });

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Lesson JSON must be an object.');
      }
      final lesson = Lesson.fromJson(_normalizeLessonJson(decoded));
      final errors = _validateLessonStructure(_normalizeLessonJson(decoded));
      if (errors.isNotEmpty) {
        throw FormatException(errors.join('; '));
      }

      final selectedClassId = widget.controller.classroomState?.classId;
      if (selectedClassId == null) {
        throw const FormatException('Select a class before saving.');
      }

      final lessonId = widget.controller.classroomState?.lessonId;
      final createdLesson = lessonId == null
          ? await widget.controller.createLesson(
              classId: selectedClassId,
              lessonDate: _parseLessonDate(lesson.lessonInfo.date),
              title: lesson.lessonInfo.title.isEmpty
                  ? 'Untitled Lesson'
                  : lesson.lessonInfo.title,
            )
          : null;

      final resolvedLessonId = createdLesson?.id ?? lessonId;
      if (resolvedLessonId == null) {
        throw const FormatException('A lesson must be selected before saving.');
      }

      await widget.controller.saveLessonEditorJson(
        lessonId: resolvedLessonId,
        classId: selectedClassId,
        lessonDate: _parseLessonDate(lesson.lessonInfo.date),
        title: lesson.lessonInfo.title.isEmpty
            ? 'Untitled Lesson'
            : lesson.lessonInfo.title,
        lesson: lesson,
      );

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _hasUnsavedChanges = false;
        _lastValidLesson = lesson;
        _statusMessage = 'Lesson saved.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _statusMessage = 'Save failed: $error';
      });
    }
  }

  DateTime _parseLessonDate(String rawDate) {
    if (rawDate.trim().isEmpty) {
      return DateTime.now();
    }
    return DateTime.tryParse(rawDate) ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final previewPhases = _lastValidLesson?.phases ?? const <LessonPhase>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Lesson Editor',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                if (_hasUnsavedChanges)
                  Text(
                    'Unsaved changes',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _importJson,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import JSON'),
                ),
                OutlinedButton.icon(
                  onPressed: _formatJson,
                  icon: const Icon(Icons.data_object),
                  label: const Text('Format JSON'),
                ),
                OutlinedButton.icon(
                  onPressed: _validateCurrentJson,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Validate'),
                ),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveLesson,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save Lesson'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _statusMessage ?? 'Ready',
              style: TextStyle(
                color: _statusMessage != null && _statusMessage!.startsWith('Invalid')
                    ? Colors.redAccent
                    : Theme.of(context).colorScheme.secondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModeToggle('Structured', _structuredMode, () => setState(() => _structuredMode = true)),
                  _buildModeToggle('Raw JSON', !_structuredMode, () => setState(() => _structuredMode = false)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_structuredMode)
              _buildStructuredEditor(previewPhases)
            else
              _buildJsonEditor(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle(String label, bool selected, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.35) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Theme.of(context).colorScheme.primary : const Color(0xFF8B949E),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStructuredEditor(List<LessonPhase> previewPhases) {
    final lessonInfo = _currentLessonJson['lessonInfo'];
    final lessonInfoMap = lessonInfo is Map ? Map<String, dynamic>.from(lessonInfo) : <String, dynamic>{};
    final phases = _phaseMapsFromCurrentLesson();
    final courseOptions = _courseOptions();
    final periodOptions = _periodOptions(lessonInfoMap['course']?.toString() ?? '');
    final dateValue = _parseDateValue(lessonInfoMap['date']?.toString() ?? '');

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    onChanged: (value) {
                      _updateLessonInfo({'title': value});
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: courseOptions.contains(lessonInfoMap['course']?.toString() ?? '')
                        ? lessonInfoMap['course']?.toString()
                        : null,
                    decoration: const InputDecoration(labelText: 'Course'),
                    items: courseOptions
                        .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      _updateLessonInfo({'course': value});
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: periodOptions.contains(lessonInfoMap['period']?.toString() ?? '')
                        ? lessonInfoMap['period']?.toString()
                        : null,
                    decoration: const InputDecoration(labelText: 'Period'),
                    items: periodOptions
                        .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      _updateLessonInfo({'period': value});
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'Date',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today_outlined),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dateValue ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            _updateLessonInfo({'date': _formatDateForJson(picked)});
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dateValue ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        _updateLessonInfo({'date': _formatDateForJson(picked)});
                        setState(() {});
                      }
                    },
                    onChanged: (value) {
                      final parsed = _parseDateValue(value);
                      if (parsed != null) {
                        _updateLessonInfo({'date': _formatDateForJson(parsed)});
                      } else if (value.trim().isNotEmpty) {
                        setState(() {
                          _statusMessage = 'Please enter a valid date like YYYY-MM-DD or Sep 4, 2026.';
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_validationErrors.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2B1618),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
            ),
            child: Text(
              _validationErrors.join('\n'),
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        const SizedBox(height: 12),
        if (phases.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: const Text('No phases yet. Add the first phase to start authoring.'),
          )
        else
          Column(
            children: [
              for (var index = 0; index < phases.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(width: double.infinity, child: _buildPhaseCard(index, phases[index])),
                ),
            ],
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: PopupMenuButton<String>(
            tooltip: 'Add phase',
            onSelected: _addPhase,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'discussion', child: Text('Discussion')),
              PopupMenuItem(value: 'instruction', child: Text('Instruction')),
              PopupMenuItem(value: 'coding', child: Text('Coding')),
              PopupMenuItem(value: 'lab', child: Text('Lab')),
              PopupMenuItem(value: 'challenge', child: Text('Challenge')),
              PopupMenuItem(value: 'reflection', child: Text('Reflection')),
              PopupMenuItem(value: 'generic', child: Text('Generic')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Add Phase',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildPhasePreview(previewPhases),
      ],
    );
  }

  void _syncStructuredFieldControllers(Object? lessonInfoValue) {
    final lessonInfo = lessonInfoValue is Map ? Map<String, dynamic>.from(lessonInfoValue) : <String, dynamic>{};
    final title = lessonInfo['title']?.toString() ?? '';
    final date = lessonInfo['date']?.toString() ?? '';

    if (_titleController.text != title) {
      final selection = _titleController.selection;
      _titleController.value = TextEditingValue(
        text: title,
        selection: selection.isValid && selection.baseOffset <= title.length
            ? selection
            : TextSelection.collapsed(offset: title.length),
      );
    }

    if (_dateController.text != date) {
      final selection = _dateController.selection;
      _dateController.value = TextEditingValue(
        text: date,
        selection: selection.isValid && selection.baseOffset <= date.length
            ? selection
            : TextSelection.collapsed(offset: date.length),
      );
    }
  }

  Widget _buildJsonEditor() {
    return Container(
      constraints: const BoxConstraints(minHeight: 420),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _editorController,
        maxLines: null,
        minLines: 24,
        expands: false,
        style: const TextStyle(
          fontFamily: 'Roboto Mono',
          fontSize: 13,
          color: Color(0xFFF0F6FC),
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Enter lesson JSON…',
          hintStyle: TextStyle(color: Color(0xFF8B949E)),
        ),
      ),
    );
  }

  Widget _buildPhaseCard(int index, Map<String, dynamic> phaseJson) {
    final phaseTitle = phaseJson['title']?.toString() ?? 'Untitled Phase';
    final phaseType = phaseJson['type']?.toString() ?? 'phase';
    final durationSeconds = int.tryParse(phaseJson['durationSeconds']?.toString() ?? '') ?? 300;
    final durationLabel = _formatDuration(durationSeconds);
    final accentColor = _phaseAccent(phaseType);
    final statusText = _phaseValidationMessage(index);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.5)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Container(
          width: 8,
          height: 40,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        title: Row(
          children: [
            Text('${index + 1}.', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                phaseTitle,
                style: const TextStyle(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: accentColor.withOpacity(0.16),
              ),
              child: Text(
                phaseType,
                style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Text(durationLabel, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
          ],
        ),
        subtitle: Text(statusText, style: TextStyle(color: statusText.contains('error') ? Colors.redAccent : const Color(0xFF8B949E), fontSize: 12)),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _movePhase(index, -1),
                icon: const Icon(Icons.arrow_upward, size: 18),
                label: const Text('↑'),
              ),
              OutlinedButton.icon(
                onPressed: () => _movePhase(index, 1),
                icon: const Icon(Icons.arrow_downward, size: 18),
                label: const Text('↓'),
              ),
              OutlinedButton.icon(
                onPressed: () => _duplicatePhase(index),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Duplicate'),
              ),
              OutlinedButton.icon(
                onPressed: () => _deletePhase(index),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
              ),
              OutlinedButton.icon(
                onPressed: () => _editPhaseJson(index),
                icon: const Icon(Icons.code, size: 18),
                label: const Text('Edit Phase JSON'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 180,
                child: TextField(
                  controller: TextEditingController(text: phaseJson['id']?.toString() ?? ''),
                  decoration: const InputDecoration(labelText: 'Phase ID'),
                  onChanged: (value) {
                    _updatePhaseField(index, 'id', value);
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  value: phaseJson['type']?.toString() ?? 'phase',
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'discussion', child: Text('Discussion')),
                    DropdownMenuItem(value: 'instruction', child: Text('Instruction')),
                    DropdownMenuItem(value: 'coding', child: Text('Coding')),
                    DropdownMenuItem(value: 'lab', child: Text('Lab')),
                    DropdownMenuItem(value: 'challenge', child: Text('Challenge')),
                    DropdownMenuItem(value: 'reflection', child: Text('Reflection')),
                    DropdownMenuItem(value: 'phase', child: Text('Generic')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _updatePhaseField(index, 'type', value);
                    }
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: TextEditingController(text: phaseJson['title']?.toString() ?? ''),
                  decoration: const InputDecoration(labelText: 'Title'),
                  onChanged: (value) {
                    _updatePhaseField(index, 'title', value);
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: _minutesFromSeconds(int.tryParse(phaseJson['durationSeconds']?.toString() ?? '') ?? 300).toString()),
                  decoration: const InputDecoration(labelText: 'Duration (min)'),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed > 0) {
                      _updatePhaseField(index, 'durationSeconds', parsed * 60);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: phaseJson['prompt']?.toString() ?? ''),
            decoration: const InputDecoration(labelText: 'Prompt'),
            minLines: 3,
            maxLines: 4,
            onChanged: (value) {
              _updatePhaseField(index, 'prompt', value);
            },
          ),
          const SizedBox(height: 12),
          _buildListField(index, 'instructions', 'Instructions'),
          const SizedBox(height: 12),
          _buildListField(index, 'teacherNotes', 'Teacher Notes'),
          const SizedBox(height: 12),
          _buildListField(index, 'discussionPrompts', 'Discussion Prompts'),
          const SizedBox(height: 12),
          _buildListField(index, 'reflectionQuestions', 'Reflection Questions'),
          const SizedBox(height: 12),
          _buildListField(index, 'keyIdeas', 'Key Ideas'),
          const SizedBox(height: 12),
          _buildListField(index, 'keyActions', 'Key Actions'),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            title: const Text('Submission enabled'),
            value: _boolFromPhase(index, 'submission', 'enabled', false),
            onChanged: (value) {
              _updateSubmission(index, 'enabled', value);
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _stringFromPhase(index, 'submission', 'mode', 'individual'),
            decoration: const InputDecoration(labelText: 'Submission mode'),
            items: const [
              DropdownMenuItem(value: 'individual', child: Text('Individual')),
              DropdownMenuItem(value: 'team', child: Text('Team')),
              DropdownMenuItem(value: 'none', child: Text('None')),
            ],
            onChanged: (value) {
              if (value != null) {
                _updateSubmission(index, 'mode', value);
              }
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            title: const Text('Confidence selector'),
            value: _boolFromPhase(index, 'submission', 'confidenceSelector', false),
            onChanged: (value) {
              _updateSubmission(index, 'confidenceSelector', value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListField(int phaseIndex, String fieldName, String label) {
    final current = _phaseValue(phaseIndex, fieldName) as List<dynamic>? ?? const <dynamic>[];
    return TextField(
      decoration: InputDecoration(labelText: label),
      minLines: 3,
      maxLines: 6,
      controller: TextEditingController(text: current.join('\n')),
      onChanged: (value) {
        _updatePhaseField(phaseIndex, fieldName, value.split('\n').map((item) => item.trim()).where((item) => item.isNotEmpty).toList());
      },
    );
  }

  Widget _buildPhasePreview(List<LessonPhase> phases) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phase Flow Preview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (phases.isEmpty)
            const Text('Preview unavailable until JSON is valid.')
          else
            SizedBox(
              width: double.infinity,
              child: LaunchpadPhaseFlow(
                items: phases
                    .map((phase) => AgendaItem(
                          title: phase.title,
                          durationMinutes: _minutesFromSeconds(phase.durationSeconds),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _updateLessonInfo(Map<String, dynamic> changes) {
    final nextJson = Map<String, dynamic>.from(_currentLessonJson);
    final lessonInfo = Map<String, dynamic>.from(nextJson['lessonInfo'] is Map ? nextJson['lessonInfo'] : <String, dynamic>{});
    lessonInfo.addAll(changes);
    nextJson['lessonInfo'] = lessonInfo;
    _syncLessonJson(nextJson);
  }

  void _updatePhaseField(int index, String fieldName, Object? value) {
    final nextJson = Map<String, dynamic>.from(_currentLessonJson);
    final phases = List<Map<String, dynamic>>.from(_phaseMapsFromCurrentLesson());
    if (index < 0 || index >= phases.length) return;
    if (fieldName == 'type' && value is String) {
      final currentId = phases[index]['id']?.toString() ?? '';
      final hasCustomId = currentId.isNotEmpty && !_looksLikeGeneratedId(currentId);
      if (!hasCustomId) {
        phases[index]['id'] = _buildUniquePhaseId(value, phases.where((phase) => phase != phases[index]).toList());
      }
    }
    phases[index][fieldName] = value;
    nextJson['phases'] = phases;
    _syncLessonJson(nextJson);
  }

  void _updateSubmission(int index, String fieldName, Object? value) {
    final nextJson = Map<String, dynamic>.from(_currentLessonJson);
    final phases = List<Map<String, dynamic>>.from(_phaseMapsFromCurrentLesson());
    if (index < 0 || index >= phases.length) return;
    final submission = Map<String, dynamic>.from(phases[index]['submission'] is Map ? phases[index]['submission'] : <String, dynamic>{});
    submission[fieldName] = value;
    phases[index]['submission'] = submission;
    nextJson['phases'] = phases;
    _syncLessonJson(nextJson);
  }

  dynamic _phaseValue(int phaseIndex, String fieldName) {
    final phases = _phaseMapsFromCurrentLesson();
    if (phaseIndex < 0 || phaseIndex >= phases.length) return null;
    return phases[phaseIndex][fieldName];
  }

  bool _boolFromPhase(int phaseIndex, String section, String fieldName, bool fallback) {
    final sectionValue = _phaseValue(phaseIndex, section);
    if (sectionValue is Map) {
      return sectionValue[fieldName] is bool ? sectionValue[fieldName] as bool : fallback;
    }
    return fallback;
  }

  String _stringFromPhase(int phaseIndex, String section, String fieldName, String fallback) {
    final sectionValue = _phaseValue(phaseIndex, section);
    if (sectionValue is Map) {
      return sectionValue[fieldName]?.toString() ?? fallback;
    }
    return fallback;
  }

  void _syncLessonJson(Map<String, dynamic> nextJson) {
    final normalized = _normalizeLessonJson(nextJson);
    final validationErrors = _validateLessonStructure(normalized);
    final lesson = Lesson.fromJson(normalized);
    if (!mounted) return;
    setState(() {
      _currentLessonJson = normalized;
      _lastValidLesson = lesson;
      _validationErrors = validationErrors;
      _hasUnsavedChanges = true;
      _updatingEditorText = true;
      _syncStructuredFieldControllers(normalized['lessonInfo']);
      _editorController.text = const JsonEncoder.withIndent('  ').convert(normalized);
      _statusMessage = validationErrors.isEmpty ? 'Structured edits applied.' : 'Structured edits applied (${validationErrors.join('; ')})';
    });
  }

  Future<void> _addPhase(String type) async {
    final existing = _phaseMapsFromCurrentLesson();
    final displayedType = type == 'generic' ? 'phase' : type;
    final nextPhase = _newPhaseJson(displayedType, existing);
    final updated = List<Map<String, dynamic>>.from(existing)..add(nextPhase);
    final nextJson = Map<String, dynamic>.from(_currentLessonJson);
    nextJson['phases'] = updated;
    _syncLessonJson(nextJson);
  }

  Future<void> _duplicatePhase(int index) async {
    final existing = _phaseMapsFromCurrentLesson();
    if (index < 0 || index >= existing.length) return;
    final source = Map<String, dynamic>.from(existing[index]);
    source['id'] = _buildUniquePhaseId(source['type']?.toString() ?? 'phase', existing);
    final updated = List<Map<String, dynamic>>.from(existing);
    updated.insert(index + 1, source);
    final nextJson = Map<String, dynamic>.from(_currentLessonJson);
    nextJson['phases'] = updated;
    _syncLessonJson(nextJson);
  }

  Future<void> _deletePhase(int index) async {
    final existing = _phaseMapsFromCurrentLesson();
    if (index < 0 || index >= existing.length) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete phase?'),
        content: const Text('This will remove the phase from the lesson JSON.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    final updated = List<Map<String, dynamic>>.from(existing)..removeAt(index);
    final nextJson = Map<String, dynamic>.from(_currentLessonJson);
    nextJson['phases'] = updated;
    _syncLessonJson(nextJson);
  }

  Future<void> _movePhase(int index, int direction) async {
    final existing = _phaseMapsFromCurrentLesson();
    if (index < 0 || index >= existing.length) return;
    final target = index + direction;
    if (target < 0 || target >= existing.length) return;
    final updated = List<Map<String, dynamic>>.from(existing);
    final item = updated.removeAt(index);
    updated.insert(target, item);
    final nextJson = Map<String, dynamic>.from(_currentLessonJson);
    nextJson['phases'] = updated;
    _syncLessonJson(nextJson);
  }

  Future<void> _editPhaseJson(int index) async {
    final existing = _phaseMapsFromCurrentLesson();
    if (index < 0 || index >= existing.length) return;
    final controller = TextEditingController(text: const JsonEncoder.withIndent('  ').convert(existing[index]));
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit Phase ${index + 1} JSON'),
          content: SizedBox(
            width: 480,
            child: TextField(
              controller: controller,
              maxLines: null,
              minLines: 16,
              expands: false,
              style: const TextStyle(fontFamily: 'Roboto Mono', fontSize: 12),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, null), child: const Text('Cancel')),
            FilledButton(onPressed: () {
              try {
                final decoded = jsonDecode(controller.text);
                if (decoded is Map<String, dynamic>) {
                  Navigator.pop(dialogContext, decoded);
                } else {
                  Navigator.pop(dialogContext, null);
                }
              } catch (_) {
                Navigator.pop(dialogContext, null);
              }
            }, child: const Text('Apply')),
          ],
        );
      },
    );
    if (result == null) return;
    final updated = List<Map<String, dynamic>>.from(existing);
    updated[index] = Map<String, dynamic>.from(result);
    final nextJson = Map<String, dynamic>.from(_currentLessonJson);
    nextJson['phases'] = updated;
    _syncLessonJson(nextJson);
  }

  String _phaseValidationMessage(int index) {
    final errors = _validationErrors.where((item) => item.toLowerCase().contains('phase')).toList();
    if (errors.isEmpty) {
      return 'Ready';
    }
    final matching = errors.where((item) => item.contains('Phase ${index + 1}') || item.contains('phase ${index + 1}') || item.contains('Phase')).toList();
    if (matching.isNotEmpty) {
      return 'error: ${matching.first}';
    }
    return 'Validation issue';
  }

  String _formatDuration(int durationSeconds) {
    final minutes = (durationSeconds / 60).round();
    return '~$minutes min';
  }

  Color _phaseAccent(String type) {
    switch (type.toLowerCase()) {
      case 'discussion':
        return const Color(0xFF56D4C6);
      case 'coding':
        return const Color(0xFF79C0FF);
      case 'reflection':
        return const Color(0xFFB084F5);
      case 'challenge':
        return const Color(0xFFFF8A7A);
      case 'instruction':
        return const Color(0xFF5EA2FF);
      case 'lab':
        return const Color(0xFFFFB454);
      default:
        return const Color(0xFF8B949E);
    }
  }

  Map<String, dynamic> _newPhaseJson(String type, List<Map<String, dynamic>> existing) {
    final normalizedType = type.isEmpty ? 'phase' : type;
    return {
      'id': _buildUniquePhaseId(normalizedType, existing),
      'type': normalizedType,
      'title': 'New Phase',
      'durationSeconds': 300,
      'prompt': '',
      'instructions': <String>[],
      'submission': {
        'enabled': false,
        'mode': 'individual',
        'confidenceSelector': false,
      },
      'teacherNotes': <String>[],
      'display': <String, dynamic>{},
      'discussionPrompts': <String>[],
      'reflectionQuestions': <String>[],
      'keyIdeas': <String>[],
      'keyActions': <String>[],
    };
  }

  bool _looksLikeGeneratedId(String id) {
    final match = RegExp(r'^[a-z0-9_]+_\d{2}$').firstMatch(id);
    return match != null;
  }

  String _buildUniquePhaseId(String type, List<Map<String, dynamic>> existing) {
    final base = type.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').trim();
    final usedIds = existing.map((phase) => phase['id']?.toString() ?? '').toSet();
    var counter = 1;
    while (true) {
      final candidate = '${base.isEmpty ? 'phase' : base}_${counter.toString().padLeft(2, '0')}';
      if (!usedIds.contains(candidate)) {
        return candidate;
      }
      counter += 1;
    }
  }

  int _minutesFromSeconds(int seconds) {
    if (seconds <= 0) return 5;
    return (seconds / 60).round().clamp(1, 999);
  }

  List<String> _courseOptions() {
    final classes = widget.controller.persistedClasses;
    final courses = <String>{};
    for (final item in classes) {
      final course = item.courseName.trim();
      if (course.isNotEmpty) {
        courses.add(course);
      }
    }
    final selectedClassCourse = widget.controller.selectedPersistedClass?.courseName.trim() ?? '';
    if (selectedClassCourse.isNotEmpty) {
      courses.add(selectedClassCourse);
    }
    return courses.toList()..sort();
  }

  List<String> _periodOptions(String selectedCourse) {
    final classes = widget.controller.persistedClasses;
    final periods = <String>{};
    for (final item in classes) {
      final course = item.courseName.trim();
      if ((selectedCourse.isEmpty || course == selectedCourse) && item.period.trim().isNotEmpty) {
        periods.add(item.period.trim());
      }
    }
    final selectedClass = widget.controller.selectedPersistedClass;
    final fallbackPeriod = selectedClass?.period.trim() ?? '';
    if (fallbackPeriod.isNotEmpty) {
      periods.add(fallbackPeriod);
    }
    return periods.toList()..sort();
  }

  String _formatDateForJson(DateTime value) => value.toIso8601String().split('T').first;

  DateTime? _parseDateValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) {
      return parsed;
    }

    final parts = trimmed.split(RegExp(r'\s+|,'));
    if (parts.length >= 3) {
      final month = _monthIndex(parts[0]);
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (month != null && day != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  int? _monthIndex(String month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final index = names.indexOf(month);
    return index >= 0 ? index + 1 : null;
  }

  List<Map<String, dynamic>> _phaseMapsFromCurrentLesson() {
    final phasesValue = _currentLessonJson['phases'];
    if (phasesValue is! List) return <Map<String, dynamic>>[];
    return phasesValue.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Map<String, dynamic> _lessonSkeleton({
    LaunchpadClassRecord? selectedClass,
    String title = '',
    String date = '',
  }) {
    final course = selectedClass?.courseName.trim().isNotEmpty == true ? selectedClass!.courseName.trim() : '';
    final period = selectedClass?.period.trim().isNotEmpty == true ? selectedClass!.period.trim() : '';
    return {
      'lessonInfo': {
        'title': title,
        'course': course,
        'period': period,
        'date': date,
      },
      'standards': <Map<String, dynamic>>[],
      'learningObjectives': <String>[],
      'successCriteria': <String>[],
      'vocabulary': <String>[],
      'materials': <String>[],
      'differentiation': <String, dynamic>{},
      'teacherMoves': <String, dynamic>{},
      'phases': [
        _newPhaseJson('discussion', const <Map<String, dynamic>>[]),
      ],
    };
  }
}
