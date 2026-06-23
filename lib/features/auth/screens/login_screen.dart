import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/theme/text_styles.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _phoneController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword     = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
      phone:    _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      context.go('/lobby');
    } else {
      final error = ref.read(authProvider).error;
      AppSnackbar.error(context, error ?? AppStrings.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Logo / Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width:  80,
                        height: 80,
                        decoration: BoxDecoration(
                          color:        AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.casino,
                          size:  48,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(AppStrings.appName ?? 'Ludo',
                          style: AppTextStyles.heading1),
                      const SizedBox(height: 8),
                      Text(
                        'Play. Win. Repeat.',
                        style: AppTextStyles.bodySecondary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                Text(AppStrings.login, style: AppTextStyles.heading2),
                const SizedBox(height: 24),

                AppTextField(
                  label:       AppStrings.phone,
                  hint:        AppStrings.phoneHint,
                  controller:  _phoneController,
                  keyboardType: TextInputType.phone,
                  validator:   Validators.phone,
                  prefixIcon:  const Icon(Icons.phone),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label:        AppStrings.password,
                  controller:   _passwordController,
                  obscureText:  _obscurePassword,
                  validator:    Validators.password,
                  prefixIcon:   const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                AppButton(
                  label:     AppStrings.login,
                  onPressed: _login,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => context.go('/register'),
                    child: RichText(
                      text: TextSpan(
                        text:  "Don't have an account? ",
                        style: AppTextStyles.bodySecondary,
                        children: [
                          TextSpan(
                            text:  AppStrings.register,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}