import 'package:flutter/material.dart';

import '../../models/launchpad_models.dart';

class LaunchpadPhaseFlow extends StatelessWidget {
  const LaunchpadPhaseFlow({
    super.key,
    required this.items,
    this.selectedIndex,
  });

  final List<AgendaItem> items;
  final int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      alignment: WrapAlignment.start,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          LaunchpadPhaseFlowItem(
            label: items[index].title,
            durationLabel: '~ ${items[index].durationMinutes} min',
            selected: index == selectedIndex,
          ),
          if (index < items.length - 1)
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF7EE787),
              size: 24,
            ),
        ],
      ],
    );
  }
}

class LaunchpadPhaseFlowItem extends StatelessWidget {
  const LaunchpadPhaseFlowItem({
    super.key,
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
