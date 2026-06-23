import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../providers/lobby_provider.dart';
import '../data/models/game_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../core/utils/formatters.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  // Fixed stake options the admin creates tables for
  final List<double> _stakeFilters = [0, 10, 50, 100, 500];
  double _selectedStake = 0;

  @override
  void initState() {
    super.initState();
    // Refresh wallet balance when lobby loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).refreshBalance();
    });
  }

  Future<void> _joinTable(GameModel game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Join Table', style: AppTextStyles.heading3),
        content: Text(
          'Stake: ${Formatters.currency(game.stakeAmount)}\n'
              'Players: ${game.playerCount}/4\n\n'
              'Your wallet will be debited immediately.',
          style: AppTextStyles.bodySecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Join'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final game_ = await ref.read(lobbyProvider.notifier).joinTable(game.id);

    if (!mounted) return;

    if (game_ != null) {
      context.go('/game/${game_.firebaseRoomId}');
    } else {
      final error = ref.read(lobbyProvider).error;
      AppSnackbar.error(context, error ?? AppStrings.error);
    }
  }

  Future<void> _leaveTable(GameModel game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Leave Table', style: AppTextStyles.heading3),
        content: Text(
          'Your stake of ${Formatters.currency(game.stakeAmount)} '
              'will be refunded to your wallet.',
          style: AppTextStyles.bodySecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ref
        .read(lobbyProvider.notifier)
        .leaveTable(game.id);

    if (!mounted) return;

    if (success) {
      AppSnackbar.success(context, 'Left table. Stake refunded.');
    } else {
      final error = ref.read(lobbyProvider).error;
      AppSnackbar.error(context, error ?? AppStrings.error);
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final lobbyState = ref.watch(lobbyProvider);
    final authState  = ref.watch(authProvider);

    ref.listen<WalletState>(walletProvider, (previous, next) {
      if (next.wallet != null) {
        ref.read(authProvider.notifier).refreshBalance();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.lobby),
        actions: [
          // Wallet balance chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical:   6,
                ),
                decoration: BoxDecoration(
                  color:        AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  Formatters.currency(authState.user?.balance ?? 0),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Wallet icon
          IconButton(
            icon:      const Icon(Icons.account_balance_wallet),
            onPressed: () => context.push('/wallet'),
          ),
          // Logout
          IconButton(
            icon:      const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),

      body: Column(
        children: [

          // Stake filter chips
          Container(
            color:   AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter by stake', style: AppTextStyles.caption),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _stakeFilters.map((stake) {
                      final isSelected = _selectedStake == stake;
                      final label = stake == 0
                          ? 'All'
                          : Formatters.currency(stake);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label:           Text(label),
                          selected:        isSelected,
                          onSelected:      (_) {
                            setState(() => _selectedStake = stake);
                            ref.read(lobbyProvider.notifier).filterByStake(
                              stake == 0 ? null : stake,
                            );
                          },
                          selectedColor:   AppColors.primary,
                          backgroundColor: AppColors.card,
                          labelStyle:      AppTextStyles.caption.copyWith(
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Tables list
          Expanded(
            child: lobbyState.isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
                : lobbyState.error != null
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lobbyState.error!,
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(lobbyProvider.notifier)
                        .loadTables(),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            )
                : lobbyState.tables.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.table_restaurant,
                    size:  64,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No tables available',
                    style: AppTextStyles.bodySecondary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Check back soon',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              color:     AppColors.primary,
              onRefresh: () async {
                ref.read(authProvider.notifier).refreshBalance();
                await ref.read(lobbyProvider.notifier).loadTables();
              },
              child: ListView.builder(
                padding:     const EdgeInsets.all(16),
                itemCount:   lobbyState.tables.length,
                itemBuilder: (context, index) {
                  final game   = lobbyState.tables[index];
                  final userId = ref.read(authProvider).user?.id ?? 0;

                  return _TableCard(
                    game:          game,
                    isJoining:     lobbyState.isJoining,
                    currentUserId: userId,
                    onJoin:        () => _joinTable(game),
                    onRejoin:      () => context.go('/game/${game.firebaseRoomId}'),
                    onLeave:       () => _leaveTable(game),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // Bottom nav
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor:     AppColors.surface,
        selectedItemColor:   AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon:  Icon(Icons.table_chart),
            label: 'Lobby',
          ),
          BottomNavigationBarItem(
            icon:  Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon:  Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
        ],
        onTap: (index) {
          if (index == 1) context.push('/wallet');
          if (index == 2) context.push('/leaderboard');
        },
      ),
    );
  }
}

// Table card widget
class _TableCard extends StatelessWidget {
  final GameModel game;
  final bool isJoining;
  final int currentUserId;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onRejoin;

  const _TableCard({
    required this.game,
    required this.isJoining,
    required this.currentUserId,
    required this.onJoin,
    required this.onLeave,
    required this.onRejoin,
  });

  Color _colorFromString(String color) {
    switch (color) {
      case 'red':    return AppColors.red;
      case 'green':  return AppColors.green;
      case 'yellow': return AppColors.yellow;
      case 'blue':   return AppColors.blue;
      default:       return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAlreadyIn = game.hasPlayer(currentUserId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(AppStrings.stake, style: AppTextStyles.caption),
                    Text(
                      Formatters.currency(game.stakeAmount),
                      style: AppTextStyles.amount.copyWith(fontSize: 20),
                    ),
                  ],
                ),

                // Action button — changes based on player state
                Row(
                  children: [
                    if (isAlreadyIn) ...[
                      // Rejoin button
                      ElevatedButton(
                        onPressed: onRejoin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          minimumSize:     const Size(80, 40),
                        ),
                        child: const Text('Rejoin'),
                      ),
                      const SizedBox(width: 8),
                      // Leave button
                      ElevatedButton(
                        onPressed: isJoining ? null : onLeave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          minimumSize:     const Size(70, 40),
                        ),
                        child: const Text('Leave'),
                      ),
                    ] else
                      ElevatedButton(
                        onPressed: game.isFull || isJoining ? null : onJoin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: game.isFull
                              ? AppColors.textHint
                              : AppColors.primary,
                          minimumSize: const Size(90, 40),
                        ),
                        child: isJoining
                            ? const SizedBox(
                          width:  16,
                          height: 16,
                          child:  CircularProgressIndicator(
                            strokeWidth: 2,
                            color:       Colors.white,
                          ),
                        )
                            : Text(
                          game.isFull
                              ? 'Full'
                              : AppStrings.joinTable,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: AppColors.surface),
            const SizedBox(height: 8),

            Row(
              children: [
                Text(
                  '${game.playerCount}/4 players',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(width: 12),
                ...game.players.map((p) => Container(
                  width:  16,
                  height: 16,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color:  _colorFromString(p.color),
                    shape:  BoxShape.circle,
                  ),
                )),
                ...List.generate(game.spotsLeft, (_) => Container(
                  width:  16,
                  height: 16,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textHint),
                    shape:  BoxShape.circle,
                  ),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}