import 'package:flutter/material.dart';

import '../../services/launchpad_controller.dart';
import '../widgets/launchpad_role_header.dart';
import 'teacher_dashboard_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.controller});

  final LaunchpadController controller;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  Future<void> _showCreateLessonDialog() async {
    final classId = widget.controller.classroomState?.classId;
    if (classId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a class before creating a lesson.')),
      );
      return;
    }

    final titleController = TextEditingController();
    final dateController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);
        return AlertDialog(
          title: const Text('Create New Lesson'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  dateController.text =
                      '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}';
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Enter a lesson title.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: dateController,
                              readOnly: true,
                              decoration: const InputDecoration(labelText: 'Date'),
                              validator: (value) {
                                if (selectedDate == DateTime(0)) {
                                  return 'Choose a valid date.';
                                }
                                return null;
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                selectedDate = picked;
                                setDialogState(() {});
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final messenger = ScaffoldMessenger.of(context);
                await widget.controller.createLesson(
                  classId: classId,
                  lessonDate: selectedDate,
                  title: titleController.text.trim(),
                );
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Lesson created.')),
                );
                navigator.pop();
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    titleController.dispose();
    dateController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF0D1117),
        title: LaunchpadRoleHeader(
          roleLabel: 'Admin',
          classes: widget.controller.persistedClasses,
          selectedClassId: widget.controller.selectedPersistedClass?.id,
          onClassChanged: (value) {
            widget.controller.updateSelectedClass(value);
          },
          lessons: widget.controller.persistedLessons,
          roleModeLabel: 'Admin Mode',
          selectedLessonId: widget.controller.selectedPersistedLesson?.id,
          onLessonChanged: (value) {
            widget.controller.updateSelectedLesson(value);
          },
          statusLabel: widget.controller.isLive ? 'Live' : 'Not Live',
          statusColor: const Color(0xFF79C0FF),
          trailingContent: const SizedBox(width: 16),
          allowCreateLesson: true,
          onCreateLesson: _showCreateLessonDialog,
          classIsLoading: widget.controller.classesLoading,
          classError: widget.controller.classesError,
          lessonIsLoading: widget.controller.lessonsLoading,
          lessonError: widget.controller.lessonsError,
          classHintText: 'Select class',
          lessonHintText: 'Select lesson',
        ),
      ),
      body: TeacherDashboardScreen(
        controller: widget.controller,
        isAdmin: true,
      ),
    );
  }
}
