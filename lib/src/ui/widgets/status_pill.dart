import 'package:flutter/material.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    this.label,
    this.color,
    this.onTap,
  });

  final String? label;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedLabel = label ?? 'Not Live';
    final resolvedColor = color ?? const Color(0xFF8B949E);
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: resolvedColor.withValues(alpha: 0.52)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: resolvedColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(resolvedLabel,
              style: TextStyle(color: resolvedColor, fontSize: 12)),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: content,
    );
  }
}
