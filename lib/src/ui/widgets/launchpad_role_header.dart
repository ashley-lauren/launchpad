import 'package:flutter/material.dart';

import '../../models/launchpad_models.dart';
import '../widgets/launchpad_class_selector.dart';

class LaunchpadRoleHeader extends StatelessWidget {
  const LaunchpadRoleHeader({
    super.key,
    required this.roleLabel,
    required this.classes,
    required this.selectedClassId,
    required this.onClassChanged,
    required this.lessons,
    required this.selectedLessonId,
    required this.onLessonChanged,
    required this.statusLabel,
    required this.statusColor,
    this.allowCreateLesson = false,
    this.onCreateLesson,
    this.classIsLoading = false,
    this.classError,
    this.lessonIsLoading = false,
    this.lessonError,
    this.classHintText,
    this.lessonHintText,
    this.roleModeLabel,
    this.centerContent,
    this.trailingContent,
  });

  final String roleLabel;
  final List<LaunchpadClassRecord> classes;
  final int? selectedClassId;
  final ValueChanged<int>? onClassChanged;
  final List<LaunchpadLessonRecord> lessons;
  final int? selectedLessonId;
  final ValueChanged<int>? onLessonChanged;
  final String statusLabel;
  final Color statusColor;
  final bool allowCreateLesson;
  final VoidCallback? onCreateLesson;
  final bool classIsLoading;
  final String? classError;
  final bool lessonIsLoading;
  final String? lessonError;
  final String? classHintText;
  final String? lessonHintText;
  final String? roleModeLabel;
  final Widget? centerContent;
  final Widget? trailingContent;

  @override
  Widget build(BuildContext context) {
    final modeLabel = roleModeLabel ?? '$roleLabel Mode';
    final defaultCenter = Row(
      children: [
        Expanded(
          child: LaunchpadClassSelector<LaunchpadClassRecord>(
            compact: true,
            items: classes,
            selectedValue: selectedClassId,
            idBuilder: (item) => item.id,
            labelBuilder: (item) => item.displayName,
            onChanged: onClassChanged,
            isLoading: classIsLoading,
            loadError: classError,
            hintText: classHintText ?? 'Select class',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _LessonSelectorDropdown(
            lessons: lessons,
            selectedLessonId: selectedLessonId,
            onLessonChanged: onLessonChanged,
            onCreateLesson: allowCreateLesson ? onCreateLesson : null,
            isLoading: lessonIsLoading,
            loadError: lessonError,
            hintText: lessonHintText ?? 'Select lesson',
          ),
        ),
      ],
    );

    final isAdminMode = roleLabel == 'Admin';
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            flex: isAdminMode ? 1 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Launchpad',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  modeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isAdminMode)
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(child: LaunchpadClassSelector<LaunchpadClassRecord>(
                        compact: true,
                        items: classes,
                        selectedValue: selectedClassId,
                        idBuilder: (item) => item.id,
                        labelBuilder: (item) => item.displayName,
                        onChanged: onClassChanged,
                        isLoading: classIsLoading,
                        loadError: classError,
                        hintText: classHintText ?? 'Select class',
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _LessonSelectorDropdown(
                        lessons: lessons,
                        selectedLessonId: selectedLessonId,
                        onLessonChanged: onLessonChanged,
                        onCreateLesson: allowCreateLesson ? onCreateLesson : null,
                        isLoading: lessonIsLoading,
                        loadError: lessonError,
                        hintText: lessonHintText ?? 'Select lesson',
                      )),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              flex: 2,
              child: centerContent ?? defaultCenter,
            ),
          const SizedBox(width: 12),
          trailingContent ?? const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _LessonSelectorDropdown extends StatelessWidget {
  const _LessonSelectorDropdown({
    required this.lessons,
    required this.selectedLessonId,
    required this.onLessonChanged,
    required this.onCreateLesson,
    required this.isLoading,
    required this.loadError,
    required this.hintText,
  });

  final List<LaunchpadLessonRecord> lessons;
  final int? selectedLessonId;
  final ValueChanged<int>? onLessonChanged;
  final VoidCallback? onCreateLesson;
  final bool isLoading;
  final String? loadError;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = const Color(0xFF1D232C);
    final borderColor = const Color(0xFF30363D);
    final textColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9);
    final mutedTextColor = Theme.of(context).colorScheme.secondary.withValues(alpha: 0.72);

    final items = <DropdownMenuItem<int>>[];
    for (final lesson in lessons) {
      items.add(
        DropdownMenuItem<int>(
          value: lesson.id,
          child: Text(
            lesson.displayLabel,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textColor),
          ),
        ),
      );
    }
    if (onCreateLesson != null) {
      items.add(
        const DropdownMenuItem<int>(
          value: -1,
          child: Text('+ Create New…', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedLessonId,
          isExpanded: true,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: mutedTextColor),
          iconEnabledColor: mutedTextColor,
          dropdownColor: surfaceColor,
          hint: Text(
            hintText,
            style: TextStyle(
              color: mutedTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          selectedItemBuilder: (context) => items
              .map(
                (item) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.child is Text ? (item.child as Text).data ?? '' : '',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              )
              .toList(),
          items: items,
          onChanged: (value) {
            if (value == -1) {
              onCreateLesson?.call();
              return;
            }
            if (value != null && onLessonChanged != null) {
              onLessonChanged!(value);
            }
          },
        ),
      ),
    );
  }
}
