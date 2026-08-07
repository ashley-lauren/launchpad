import 'package:flutter/material.dart';

class LaunchpadClassSelector<T> extends StatelessWidget {
  const LaunchpadClassSelector({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.idBuilder,
    required this.labelBuilder,
    required this.onChanged,
    this.compact = false,
    this.isLoading = false,
    this.loadError,
    this.hintText,
  });

  final List<T> items;
  final int? selectedValue;
  final int Function(T item) idBuilder;
  final String Function(T item) labelBuilder;
  final ValueChanged<int>? onChanged;
  final bool compact;
  final bool isLoading;
  final String? loadError;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = const Color(0xFF1D232C);
    final borderColor = const Color(0xFF30363D);
    final textColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.86);
    final mutedTextColor = Theme.of(context).colorScheme.secondary.withValues(alpha: 0.72);
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 12);

    final child = Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(compact ? 999 : 12),
        border: Border.all(color: borderColor),
      ),
      padding: padding,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedValue,
          isExpanded: true,
          selectedItemBuilder: (context) => items
              .map(
                (item) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    labelBuilder(item),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: textColor,
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          isDense: compact,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: compact ? 18 : 20,
            color: mutedTextColor,
          ),
          iconEnabledColor: mutedTextColor,
          dropdownColor: surfaceColor,
          hint: Text(
            hintText ?? 'Select',
            style: TextStyle(
              color: mutedTextColor,
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextStyle(
            color: textColor,
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<int>(
                  value: idBuilder(item),
                  child: Text(
                    labelBuilder(item),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(color: textColor),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged == null
              ? null
              : (value) {
                  if (value != null) {
                    onChanged!(value);
                  }
                },
        ),
      ),
    );

    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(compact ? 999 : 12),
          border: Border.all(color: borderColor),
        ),
        padding: padding,
        child: Text(
          'Loading…',
          style: TextStyle(color: textColor, fontSize: compact ? 13 : 14),
        ),
      );
    }

    if (loadError != null) {
      return Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(compact ? 999 : 12),
          border: Border.all(color: borderColor),
        ),
        padding: padding,
        child: Text(
          'Unable to load',
          style: TextStyle(color: Colors.redAccent, fontSize: compact ? 13 : 14),
        ),
      );
    }

    return child;
  }
}
