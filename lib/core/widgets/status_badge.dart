import 'package:flutter/material.dart';

import '../theme/cursar_palette.dart';
import '../theme/cursar_theme.dart';
import '../theme/cursar_tone.dart';

/// Etiqueta de estado (espejo de `StatusBadge` de `adminCursarF`).
///
/// Muestra un texto corto con fondo tintado y color según el [tone].
class StatusBadge extends StatelessWidget {
  final String text;
  final Tone tone;

  const StatusBadge(this.text, {super.key, this.tone = Tone.neutral});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.bg(p),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.fg(p).withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tone.fg(p),
          fontSize: AppTokens.xs,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
