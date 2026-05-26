import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../widgets/common_widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
    _fadeCtrl.reset();
    _fadeCtrl.forward();
    ref.read(authViewModelProvider.notifier).clearError();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = ref.read(authViewModelProvider.notifier);
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    bool success;
    if (_isLogin) {
      success = await vm.login(email, password);
    } else {
      success = await vm.signUp(email, password);
    }

    if (success && mounted) {
      final firebaseService = ref.read(firebaseServiceProvider);
      final hasOnboarding = await firebaseService
          .hasCompletedOnboarding(firebaseService.currentUser!.uid);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
          hasOnboarding ? const HomeScreen() : const OnboardingScreen(),
        ),
      );
    }
  }

  Future<void> _enterAsGuest() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not continue as guest. Try again.',
                style: AppTextStyles.bodySmall(color: Colors.white)),
            backgroundColor: AppColors.cardLight,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StarBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingXXL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSizes.paddingXXL),

                    // Logo
                    Row(
                      children: [
                        Icon(Icons.restaurant_outlined,
                            size: 13,
                            color: AppColors.accent.withValues(alpha: 0.4)),
                        const SizedBox(width: 6),
                        Text('Fit Foodie',
                            style: AppTextStyles.logoSmall(
                                color:
                                AppColors.accent.withValues(alpha: 0.4))),
                      ],
                    ),

                    const SizedBox(height: AppSizes.paddingHuge),

                    Text(
                      _isLogin ? 'Welcome back.' : 'Create account.',
                      style: AppTextStyles.logoLarge(),
                    ),
                    const SizedBox(height: AppSizes.paddingSM),
                    Text(
                      _isLogin
                          ? 'Sign in to continue tracking.'
                          : 'Start eating what you love.',
                      style: AppTextStyles.bodyMedium(
                          color: AppColors.accent.withValues(alpha: 0.5)),
                    ),

                    const SizedBox(height: AppSizes.paddingHuge),

                    // Email
                    Text('EMAIL', style: AppTextStyles.label()),
                    const SizedBox(height: AppSizes.paddingSM),
                    _InputField(
                      controller: _emailCtrl,
                      hint: 'your@email.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email required';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSizes.paddingLG),

                    // Password
                    Text('PASSWORD', style: AppTextStyles.label()),
                    const SizedBox(height: AppSizes.paddingSM),
                    _InputField(
                      controller: _passwordCtrl,
                      hint: 'Enter your password',
                      obscure: _obscurePass,
                      suffix: GestureDetector(
                        onTap: () =>
                            setState(() => _obscurePass = !_obscurePass),
                        child: Icon(
                          _obscurePass
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: AppColors.accent.withValues(alpha: 0.4),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password required';
                        if (v.length < 6) return 'Min 6 characters';
                        return null;
                      },
                    ),

                    if (!_isLogin) ...[
                      const SizedBox(height: AppSizes.paddingLG),
                      Text('CONFIRM PASSWORD', style: AppTextStyles.label()),
                      const SizedBox(height: AppSizes.paddingSM),
                      _InputField(
                        controller: _confirmCtrl,
                        hint: 'Enter your password',
                        obscure: _obscureConfirm,
                        suffix: GestureDetector(
                          onTap: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                          child: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                            color: AppColors.accent.withValues(alpha: 0.4),
                          ),
                        ),
                        validator: (v) {
                          if (v != _passwordCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: AppSizes.paddingXXL),

                    // Error
                    if (authState.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSizes.paddingMD),
                        decoration: BoxDecoration(
                          color: const Color(0x15FF6B6B),
                          borderRadius:
                          BorderRadius.circular(AppSizes.radiusMD),
                          border:
                          Border.all(color: const Color(0x30FF6B6B)),
                        ),
                        child: Text(authState.error!,
                            style: AppTextStyles.bodySmall(
                                color: const Color(0xCCFF6B6B))),
                      ),
                      const SizedBox(height: AppSizes.paddingLG),
                    ],

                    // Submit
                    PrimaryButton(
                      label: _isLogin ? 'SIGN IN' : 'CREATE ACCOUNT',
                      isLoading: authState.isLoading,
                      onTap: _submit,
                      margin: EdgeInsets.zero,
                    ),

                    const SizedBox(height: AppSizes.paddingXL),

                    // Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin
                              ? "Don't have an account? "
                              : 'Already have an account? ',
                          style: AppTextStyles.bodySmall(
                              color: AppColors.accent.withValues(alpha: 0.4)),
                        ),
                        GestureDetector(
                          onTap: _toggleMode,
                          child: Text(
                            _isLogin ? 'Sign up' : 'Sign in',
                            style: AppTextStyles.bodySmall(
                                color: AppColors.accent),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSizes.paddingXXL),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                            child: Container(
                                height: 1,
                                color: AppColors.accent.withValues(alpha: 0.08))),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingMD),
                          child: Text('OR',
                              style: AppTextStyles.label(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.3))),
                        ),
                        Expanded(
                            child: Container(
                                height: 1,
                                color: AppColors.accent.withValues(alpha: 0.08))),
                      ],
                    ),

                    const SizedBox(height: AppSizes.paddingXL),

                    // ── GUEST BUTTON — HIGHLY VISIBLE ──
                    GestureDetector(
                      onTap: _enterAsGuest,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.paddingMD + 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'CONTINUE AS GUEST',
                            style: AppTextStyles.buttonSecondary(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSizes.paddingSM),
                    Center(
                      child: Text(
                        'No account needed to explore',
                        style: AppTextStyles.bodySmall(
                            color: AppColors.accent.withValues(alpha: 0.35)),
                      ),
                    ),

                    const SizedBox(height: AppSizes.paddingHuge),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── INPUT FIELD ───────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.inputField(),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        style: AppTextStyles.bodyLarge(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyLarge(
              color: AppColors.accent.withValues(alpha: 0.25)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingLG,
              vertical: AppSizes.paddingMD),
          suffixIcon: suffix != null
              ? Padding(
              padding:
              const EdgeInsets.only(right: AppSizes.paddingMD),
              child: suffix)
              : null,
          errorStyle: AppTextStyles.bodySmall(
              color: const Color(0xCCFF6B6B)),
        ),
      ),
    );
  }
}