import 'package:flutter/material.dart';

enum CalculatorButtonTone {
  neutral,
  accent,
  danger,
  success,
}

class CalculatorButton extends StatelessWidget {
  const CalculatorButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.tone,
  });

  final String label;
  final VoidCallback onPressed;
  final CalculatorButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = _resolveColors(scheme);
    final textScale = label.length > 3 ? 0.76 : 1.0;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colors.border,
            width: 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.shadow.withOpacity(0.14),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.foreground,
                  fontSize: 24 * textScale,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ResolvedButtonColors _resolveColors(ColorScheme scheme) {
    switch (tone) {
      case CalculatorButtonTone.accent:
        return _ResolvedButtonColors(
          background: scheme.primary.withOpacity(0.18),
          foreground: scheme.onSurface,
          border: scheme.primary.withOpacity(0.45),
        );
      case CalculatorButtonTone.danger:
        return _ResolvedButtonColors(
          background: scheme.error.withOpacity(0.16),
          foreground: scheme.onSurface,
          border: scheme.error.withOpacity(0.38),
        );
      case CalculatorButtonTone.success:
        return _ResolvedButtonColors(
          background: scheme.secondary.withOpacity(0.18),
          foreground: scheme.onSurface,
          border: scheme.secondary.withOpacity(0.42),
        );
      case CalculatorButtonTone.neutral:
        return _ResolvedButtonColors(
          background: scheme.surfaceContainerHighest.withOpacity(0.78),
          foreground: scheme.onSurface,
          border: scheme.outlineVariant,
        );
    }
  }
}

class _ResolvedButtonColors {
  const _ResolvedButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}
