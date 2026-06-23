import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/wallet_provider.dart';
import '../data/models/transaction_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../core/utils/formatters.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).loadWallet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.wallet),
        actions: [
          IconButton(
            icon:      const Icon(Icons.refresh),
            onPressed: () => ref.read(walletProvider.notifier).loadWallet(),
          ),
        ],
      ),
      body: walletState.isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : RefreshIndicator(
        color:     AppColors.primary,
        onRefresh: () => ref.read(walletProvider.notifier).loadWallet(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Balance card
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF2E7D32)],
                    begin:  Alignment.topLeft,
                    end:    Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.balance,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.currency(
                        walletState.wallet?.balance ?? 0,
                      ),
                      style: AppTextStyles.amount.copyWith(
                        fontSize: 32,
                        color:    Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _StatChip(
                          label: 'Won',
                          value: Formatters.currency(
                            walletState.wallet?.totalWon ?? 0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          label: 'Lost',
                          value: Formatters.currency(
                            walletState.wallet?.totalLost ?? 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/wallet/deposit'),
                      icon:  const Icon(Icons.add),
                      label: const Text(AppStrings.deposit),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showWithdrawSheet(context, ref),
                      icon:  const Icon(Icons.arrow_upward),
                      label: const Text(AppStrings.withdraw),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Deposited',
                      value: Formatters.currency(
                        walletState.wallet?.totalDeposited ?? 0,
                      ),
                      icon:  Icons.arrow_downward,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Withdrawn',
                      value: Formatters.currency(
                        walletState.wallet?.totalWithdrawn ?? 0,
                      ),
                      icon:  Icons.arrow_upward,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Transactions
              const Text(
                AppStrings.transactions,
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 12),

              walletState.transactions.isEmpty
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No transactions yet',
                    style: AppTextStyles.bodySecondary,
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap:  true,
                physics:     const NeverScrollableScrollPhysics(),
                itemCount:   walletState.transactions.length,
                itemBuilder: (context, index) {
                  return _TransactionTile(
                    transaction: walletState.transactions[index],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWithdrawSheet(BuildContext context, WidgetRef ref) {
    final phoneController  = TextEditingController();
    final amountController = TextEditingController();

    showModalBottomSheet(
      context:       context,
      isScrollControlled: true,
      backgroundColor:    AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left:    24,
          right:   24,
          top:     24,
          bottom:  MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.withdraw, style: AppTextStyles.heading3),
            const SizedBox(height: 24),
            TextField(
              controller:   phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'MPESA Phone',
                hintText:  '2547XXXXXXXX',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller:   amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText:  'Amount (KES)',
                prefixIcon: Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 24),
            Consumer(
              builder: (ctx, ref, _) {
                final isWithdrawing =
                    ref.watch(walletProvider).isWithdrawing;
                return ElevatedButton(
                  onPressed: isWithdrawing
                      ? null
                      : () async {
                    final amount = double.tryParse(
                      amountController.text,
                    );
                    if (amount == null) return;

                    final success = await ref
                        .read(walletProvider.notifier)
                        .withdraw(
                      phone:  phoneController.text.trim(),
                      amount: amount,
                    );

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);

                    if (success) {
                      AppSnackbar.success(
                        context,
                        'Withdrawal initiated successfully.',
                      );
                    } else {
                      final error = ref.read(walletProvider).error;
                      AppSnackbar.error(
                        context,
                        error ?? AppStrings.error,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                  ),
                  child: isWithdrawing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(AppStrings.withdraw),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:        Colors.white12,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
              AppTextStyles.caption.copyWith(color: Colors.white70)),
          Text(value,
              style: AppTextStyles.caption.copyWith(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding:      const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:        color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(value,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color:      AppColors.textPrimary,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionTile({required this.transaction});

  IconData get _icon {
    switch (transaction.type) {
      case 'deposit':    return Icons.arrow_downward;
      case 'withdrawal': return Icons.arrow_upward;
      case 'win':        return Icons.emoji_events;
      case 'stake':      return Icons.casino;
      case 'refund':     return Icons.replay;
      default:           return Icons.swap_horiz;
    }
  }

  Color get _color {
    return transaction.isCredit ? AppColors.success : AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding:    const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:        _color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon, color: _color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.type.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color:      AppColors.textPrimary,
                  ),
                ),
                if (transaction.description != null)
                  Text(
                    transaction.description!,
                    style:     AppTextStyles.caption,
                    maxLines:  1,
                    overflow:  TextOverflow.ellipsis,
                  ),
                Text(
                  transaction.createdAt,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${transaction.isCredit ? '+' : '-'}'
                '${Formatters.currency(transaction.amount)}',
            style: AppTextStyles.body.copyWith(
              color:      _color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}