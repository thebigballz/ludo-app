import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/wallet_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_snackbar.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _phoneController  = TextEditingController();
  final _amountController = TextEditingController();

  final List<double> _quickAmounts = [50, 100, 200, 500, 1000];

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _deposit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    final success = await ref.read(walletProvider.notifier).deposit(
      phone:  _phoneController.text.trim(),
      amount: amount,
    );

    if (!mounted) return;

    if (success) {
      AppSnackbar.success(
        context,
        'STK push sent. Enter your MPESA PIN to complete.',
      );
      context.pop();
    } else {
      final error = ref.read(walletProvider).error;
      AppSnackbar.error(context, error ?? AppStrings.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDepositing = ref.watch(walletProvider).isDepositing;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.deposit)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:        AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You will receive an MPESA prompt on your phone. '
                            'Enter your PIN to complete the deposit.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              AppTextField(
                label:        'MPESA Phone',
                hint:         AppStrings.phoneHint,
                controller:   _phoneController,
                keyboardType: TextInputType.phone,
                validator:    Validators.phone,
                prefixIcon:   const Icon(Icons.phone),
              ),

              const SizedBox(height: 16),

              AppTextField(
                label:        'Amount (KES)',
                controller:   _amountController,
                keyboardType: TextInputType.number,
                validator:    (v) => Validators.amount(v),
                prefixIcon:   const Icon(Icons.money),
              ),

              const SizedBox(height: 16),

              // Quick amount buttons
              const Text('Quick amounts', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _quickAmounts.map((amount) {
                  return ActionChip(
                    label: Text('KES ${amount.toInt()}'),
                    backgroundColor: AppColors.card,
                    onPressed: () => setState(() {
                      _amountController.text = amount.toInt().toString();
                    }),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              AppButton(
                label:     AppStrings.deposit,
                onPressed: _deposit,
                isLoading: isDepositing,
                color:     AppColors.success,
              ),
            ],
          ),
        ),
      ),
    );
  }
}