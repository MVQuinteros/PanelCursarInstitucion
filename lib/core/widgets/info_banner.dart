import 'package:flutter/material.dart';

import '../theme/cursar_palette.dart';
import '../theme/cursar_theme.dart';
import '../theme/cursar_tone.dart';

/// Banner informativo (espejo de `Banner` de `adminCursarF`).
///
/// Se usa para avisos contextuales dentro de una pantalla (por ejemplo,
/// "tu institución está pendiente de aprobación").
class InfoBanner extends StatelessWidget {
  final String message;
  final Tone tone;
  final IconData icon;

  const InfoBanner({
    super.key,
    required this.message,
    this.tone = Tone.info,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tone.bg(p),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: tone.fg(p).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: tone.fg(p)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: tone.fg(p), fontSize: AppTokens.sm),
            ),
          ),
        ],
      ),
    );
  }
}
