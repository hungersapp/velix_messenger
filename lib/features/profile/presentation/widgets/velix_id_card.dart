import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/profile_identity.dart';
import '../l10n/profile_localizations.dart';

class VelixIdCard extends StatelessWidget {
  const VelixIdCard({
    super.key,
    required this.identity,
  });

  final ProfileIdentity identity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = ProfileLocalizations.of(context);

    return Material(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.badge_outlined,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Velix ID',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    identity.handle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Copy',
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: identity.handle),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.velixIdCopied)),
                );
              },
              icon: Icon(
                Icons.copy_rounded,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
