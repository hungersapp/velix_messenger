import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../contacts/presentation/providers/contacts_provider.dart';

/// Compact friend counters for the profile screen.
///
/// Invite-sourced friendships are not tracked yet, so Invite Friends stays at 0.
/// Existing friends are treated as QR Friends.
class FriendsStatisticsCard extends ConsumerStatefulWidget {
  const FriendsStatisticsCard({super.key});

  @override
  ConsumerState<FriendsStatisticsCard> createState() =>
      _FriendsStatisticsCardState();
}

class _FriendsStatisticsCardState
    extends ConsumerState<FriendsStatisticsCard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(friendsProvider.notifier).loadFriends();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final friendsState = ref.watch(friendsProvider);
    final totalFriends = friendsState.friends.length;
    final qrFriends = totalFriends;
    const inviteFriends = 0;

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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Friends Statistics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'QR Friends',
                    value: qrFriends,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Invite Friends',
                    value: inviteFriends,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Total Friends',
                    value: totalFriends,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          '$value',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
