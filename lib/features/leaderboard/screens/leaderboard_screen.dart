import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/leaderboard_provider.dart';
import '../data/models/leaderboard_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/theme/text_styles.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state   = ref.watch(leaderboardProvider);
    final userId  = ref.watch(authProvider).user?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon:      const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(leaderboardProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      )
          : state.error != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.error!,
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(leaderboardProvider.notifier)
                  .load(),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      )
          : state.players.isEmpty
          ? const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.leaderboard,
              size:  64,
              color: AppColors.textHint,
            ),
            SizedBox(height: 16),
            Text(
              'No players yet',
              style: AppTextStyles.bodySecondary,
            ),
          ],
        ),
      )
          : RefreshIndicator(
        color:     AppColors.primary,
        onRefresh: () => ref
            .read(leaderboardProvider.notifier)
            .load(),
        child: ListView.builder(
          padding:     const EdgeInsets.all(16),
          itemCount:   state.players.length,
          itemBuilder: (context, index) {
            return _LeaderboardTile(
              entry:   state.players[index],
              isMe:    state.players[index].id == userId,
            );
          },
        ),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;

  const _LeaderboardTile({
    required this.entry,
    required this.isMe,
  });

  Color get _rankColor {
    switch (entry.rank) {
      case 1:  return const Color(0xFFFFD700); // Gold
      case 2:  return const Color(0xFFC0C0C0); // Silver
      case 3:  return const Color(0xFFCD7F32); // Bronze
      default: return AppColors.textHint;
    }
  }

  Widget get _rankWidget {
    if (entry.rank <= 3) {
      return Text(
        entry.rank == 1 ? '🥇' : entry.rank == 2 ? '🥈' : '🥉',
        style: const TextStyle(fontSize: 24),
      );
    }
    return Text(
      '#${entry.rank}',
      style: AppTextStyles.body.copyWith(
        color:      _rankColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin:   const EdgeInsets.only(bottom: 8),
      padding:  const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withValues(alpha: 0.5)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(width: 40, child: Center(child: _rankWidget)),
          const SizedBox(width: 12),

          // Avatar
          CircleAvatar(
            radius:          22,
            backgroundColor: AppColors.surface,
            child: Text(
              entry.name[0].toUpperCase(),
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isMe
                            ? AppColors.secondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical:   2,
                        ),
                        decoration: BoxDecoration(
                          color:        AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'You',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.totalGames} games · '
                      '${entry.winRate}% win rate',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          // Wins count
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalWins}',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              const Text(
                'wins',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}