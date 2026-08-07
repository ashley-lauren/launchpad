import 'package:flutter/material.dart';

import '../../models/launchpad_models.dart';
import '../../services/launchpad_controller.dart';

class TableLayoutBuilder extends StatefulWidget {
  const TableLayoutBuilder({super.key, required this.controller});

  final LaunchpadController controller;

  @override
  State<TableLayoutBuilder> createState() => _TableLayoutBuilderState();
}

class _TableLayoutBuilderState extends State<TableLayoutBuilder> {
  late final TextEditingController _nameController;
  late final TextEditingController _tableCountController;
  late final TextEditingController _constraintsController;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    _nameController = TextEditingController(
      text: widget.controller.tableLayoutEditorName ?? '',
    );
    _tableCountController = TextEditingController(
      text: widget.controller.tableLayoutEditorTableCount.toString(),
    );
    _constraintsController = TextEditingController(
      text: widget.controller.tableLayoutEditorConstraintsText,
    );
  }

  @override
  void didUpdateWidget(covariant TableLayoutBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
    if (oldWidget.controller.tableLayoutEditorName !=
        widget.controller.tableLayoutEditorName) {
      _nameController.text = widget.controller.tableLayoutEditorName ?? '';
    }
    if (oldWidget.controller.tableLayoutEditorTableCount !=
        widget.controller.tableLayoutEditorTableCount) {
      _tableCountController.text =
          widget.controller.tableLayoutEditorTableCount.toString();
    }
    if (oldWidget.controller.tableLayoutEditorConstraintsText !=
        widget.controller.tableLayoutEditorConstraintsText) {
      _constraintsController.text =
          widget.controller.tableLayoutEditorConstraintsText;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _nameController.dispose();
    _tableCountController.dispose();
    _constraintsController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final layouts = widget.controller.persistedTableLayouts;
    final students = widget.controller.persistedStudents;
    final selectedLayoutId = widget.controller.tableLayoutEditorSelectionId;
    final tableCount = widget.controller.tableLayoutEditorTableCount;
    final assignments = widget.controller.tableLayoutEditorAssignments;
    final selectedClass = widget.controller.selectedPersistedClass;

    final assignedStudentIds = assignments.keys.toSet();
    final unassignedStudents = students
        .where((student) => !assignedStudentIds.contains(student.id))
        .toList();

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
                    'Table Assignments',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                if (widget.controller.tableLayoutEditorDirty)
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
            if (selectedClass == null)
              Text(
                'Select a class to load students and saved layouts.',
                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
              )
            else ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<int?>(
                      value: selectedLayoutId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Table Layout'),
                      items: [
                        ...layouts.map((layout) => DropdownMenuItem<int>(
                              value: layout.id,
                              child: Text(layout.name),
                            )),
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('+ Create New…'),
                        ),
                      ],
                      onChanged: (value) async {
                        if (value == null) {
                          await _showCreateDialog();
                        } else {
                          await widget.controller.selectTableLayoutEditor(value);
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Layout Name'),
                      onChanged: widget.controller.updateTableLayoutEditorName,
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Number of Tables'),
                      keyboardType: TextInputType.number,
                      controller: _tableCountController,
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed != null) {
                          widget.controller.updateTableLayoutEditorTableCount(parsed);
                        }
                      },
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      try {
                        await widget.controller.saveTableLayoutEditor();
                        if (!mounted) return;
                        messenger?.showSnackBar(
                          const SnackBar(content: Text('Layout saved.')),
                        );
                      } catch (error) {
                        if (!mounted) return;
                        messenger?.showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Layout'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      try {
                        await widget.controller.randomizeTableLayoutEditor();
                      } catch (error) {
                        if (!mounted) return;
                        messenger?.showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    },
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Randomize Students'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDropZone(context, unassignedStudents, tableCount, assignments),
              const SizedBox(height: 16),
              _buildRandomizationOptions(context),
              const SizedBox(height: 12),
              _buildConstraintEditor(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropZone(
    BuildContext context,
    List<LaunchpadStudentRecord> unassignedStudents,
    int tableCount,
    Map<int, int> assignments,
  ) {
    final cards = <Widget>[];
    for (var index = 1; index <= tableCount; index++) {
      cards.add(_buildTableCard(context, index, assignments));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUnassignedArea(context, unassignedStudents),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1200
                ? 3
                : constraints.maxWidth >= 720
                    ? 2
                    : 1;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.05,
              children: cards,
            );
          },
        ),
      ],
    );
  }

  Widget _buildUnassignedArea(
    BuildContext context,
    List<LaunchpadStudentRecord> students,
  ) {
    return SizedBox(
      width: double.infinity,
      child: _buildTableCardShell(
        context,
        title: 'Unassigned Students',
        subtitle: '${students.length}',
        children: students.map((student) => _buildStudentChip(student, null)).toList(),
        dropTarget: true,
        tableNumber: 0,
      ),
    );
  }

  Widget _buildTableCard(
    BuildContext context,
    int tableNumber,
    Map<int, int> assignments,
  ) {
    final students = widget.controller.persistedStudents.where((student) {
      return assignments[student.id] == tableNumber;
    }).toList();

    return _buildTableCardShell(
      context,
      title: 'Table $tableNumber',
      subtitle: '${students.length}',
      children: students.map((student) => _buildStudentChip(student, tableNumber)).toList(),
      dropTarget: true,
      tableNumber: tableNumber,
    );
  }

  Widget _buildTableCardShell(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Widget> children,
    required bool dropTarget,
    required int tableNumber,
  }) {
    final accent = Theme.of(context).colorScheme.primary.withValues(alpha: 0.24);
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final studentId = details.data;
        widget.controller.moveStudentToTable(
          studentId: studentId,
          tableNumber: tableNumber == 0 ? null : tableNumber,
        );
      },
      builder: (context, candidateData, rejectedData) {
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 150, maxHeight: 176),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10161F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: candidateData.isNotEmpty ? accent : const Color(0xFF30363D),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.72),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8B949E)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: children.isEmpty
                      ? const Text('Drop students here', style: TextStyle(color: Color(0xFF8B949E), fontSize: 12))
                      : Wrap(spacing: 6, runSpacing: 6, children: children),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRandomizationOptions(BuildContext context) {
    final options = widget.controller.tableLayoutEditorRandomizationOptions;
    final summary = widget.controller.tableLayoutEditorRandomizationSummary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121A23),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Randomization Options',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              CheckboxListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: options.balanceTableSizes,
                onChanged: (value) => widget.controller.updateTableLayoutEditorRandomizationOptions(
                  balanceTableSizes: value,
                ),
                title: const Text('Balance table sizes'),
              ),
              CheckboxListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: options.preferNewTablemates,
                onChanged: (value) => widget.controller.updateTableLayoutEditorRandomizationOptions(
                  preferNewTablemates: value,
                ),
                title: const Text('Prefer new tablemates'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CheckboxListTile.adaptive(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: options.avoidRecentTablemates > 0,
            onChanged: (value) => widget.controller.updateTableLayoutEditorRandomizationOptions(
              avoidRecentTablemates: value == true ? 2 : 0,
            ),
            title: const Text('Avoid previous tablemates'),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Row(
              children: [
                const Text('Previous layouts to consider'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    enabled: options.avoidRecentTablemates > 0,
                    controller: TextEditingController(text: options.avoidRecentTablemates.toString()),
                    decoration: const InputDecoration(isDense: true),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null) {
                        widget.controller.updateTableLayoutEditorRandomizationOptions(
                          avoidRecentTablemates: parsed,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          if (summary != null && summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              summary,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConstraintEditor(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121A23),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seating Constraints',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _constraintsController,
            onChanged: widget.controller.updateTableLayoutEditorConstraintsText,
            maxLines: 8,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'Enter constraints here…',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Examples',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'avoid: Tatum, Iris',
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.65)),
          ),
          Text(
            'together: Jasper, Sienna',
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.65)),
          ),
          Text(
            'lock: Quinn -> Table 2',
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.65)),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentChip(LaunchpadStudentRecord student, int? tableNumber) {
    return Draggable<int>(
      data: student.id,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Text(student.label),
        ),
      ),
      childWhenDragging: const SizedBox.shrink(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.24)),
        ),
        child: Text(student.label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    _nameController.text = '';
    _tableCountController.text = '6';
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create New Layout'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Layout Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tableCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Number of Tables'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(_tableCountController.text);
              if (parsed != null) {
                widget.controller.startNewTableLayoutEditor(
                  name: _nameController.text,
                  tableCount: parsed,
                );
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (created == true && mounted) {
      setState(() {});
    }
  }
}
