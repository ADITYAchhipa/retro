import 'package:flutter/material.dart';

/// A unified, modern card used across the app for consistent styling.
/// - Supports tappable ripple, leading/trailing, header/title/subtitle, and actions.
/// - Honors Theme.cardTheme while applying subtle polish like border/shadow.
class UnifiedCard extends StatelessWidget {
  final Widget? leading;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget>? actions;
  final Widget? child;
  final EdgeInsetsGeometry? contentPadding;
  final GestureTapCallback? onTap;
  final Color? statusColor; // draws a slim colored bar on top when provided
  final bool outlined;
  final bool dense;

  const UnifiedCard({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.actions,
    this.child,
    this.contentPadding,
    this.onTap,
    this.statusColor,
    this.outlined = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseShape = theme.cardTheme.shape ??
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    final shape = outlined
        ? RoundedRectangleBorder(
            borderRadius: (baseShape is RoundedRectangleBorder)
                ? baseShape.borderRadius
                : BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
          )
        : baseShape;

    final content = Padding(
      padding: contentPadding ?? EdgeInsets.all(dense ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null || title != null || trailing != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (child != null) SizedBox(height: dense ? 8 : 12),
          ],
          if (child != null) child!,
          if (actions != null && actions!.isNotEmpty) ...[
            SizedBox(height: dense ? 8 : 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: actions!,
            ),
          ],
        ],
      ),
    );

    final core = Stack(
      children: [
        Material(
          color: theme.cardTheme.color,
          elevation: theme.cardTheme.elevation ?? (outlined ? 0 : 8),
          shadowColor: theme.cardTheme.shadowColor,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: content,
          ),
        ),
        if (statusColor != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
          ),
      ],
    );

    // Respect Theme.cardTheme.margin externally
    final margin = Theme.of(context).cardTheme.margin;
    if (margin != null) {
      return Padding(padding: margin, child: core);
    }
    return core;
  }
}
