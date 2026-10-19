import 'package:flutter/material.dart';

import '../theme/cursar_palette.dart';

/// Placeholder de carga (espejo de `LoadingCard` de `adminCursarF`).
class LoadingCard extends StatelessWidget {
  final String? label;

  const LoadingCard({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            if (label != null) ...[
              const SizedBox(height: 12),
              Text(label!, style: TextStyle(color: p.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}
