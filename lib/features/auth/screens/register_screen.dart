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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey                = GlobalKey<FormState>();
  final _nameController         = TextEditingController();
  final _phoneController        = TextEditingController();
  final _passwordController     = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword         = true;
  bool _obscureConfirmPassword  = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).register(
      name:                 _nameController.text.trim(),
      phone:                _phoneController.text.trim(),
      password:             _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
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
      appBar: AppBar(
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.register, style: AppTextStyles.heading2),
                const SizedBox(height: 8),
                Text(
                  'Create your account to start playing',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: 32),

                AppTextField(
                  label:      AppStrings.name,
                  controller: _nameController,
                  validator:  Validators.name,
                  prefixIcon: const Icon(Icons.person),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label:        AppStrings.phone,
                  hint:         AppStrings.phoneHint,
                  controller:   _phoneController,
                  keyboardType: TextInputType.phone,
                  validator:    Validators.phone,
                  prefixIcon:   const Icon(Icons.phone),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label:       AppStrings.password,
                  controller:  _passwordController,
                  obscureText: _obscurePassword,
                  validator:   Validators.password,
                  prefixIcon:  const Icon(Icons.lock),
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
                const SizedBox(height: 16),

                AppTextField(
                  label:       AppStrings.confirmPassword,
                  controller:  _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  validator:   (value) => Validators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                AppButton(
                  label:     AppStrings.register,
                  onPressed: _register,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: RichText(
                      text: TextSpan(
                        text:  'Already have an account? ',
                        style: AppTextStyles.bodySecondary,
                        children: [
                          TextSpan(
                            text:  AppStrings.login,
                            style: AppTextStyles.body.copyWith(
                              color:      AppColors.primary,
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