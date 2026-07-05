import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _loading = true);
    await context.read<AuthCubit>().sendOtp(email);
    if (!mounted) return;
    setState(() => _loading = false);
    // Navigate to OTP entry regardless of result — Supabase always returns
    // success to avoid user enumeration.
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<AuthCubit>(),
        child: OtpScreen(email: email),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 64),
                Text('MenuApp', style: AppTextStyles.h1),
                const SizedBox(height: 8),
                Text(
                  'Plan meals together.',
                  style: AppTextStyles.body.copyWith(color: AppColors.ink3),
                ),
                const SizedBox(height: 48),
                Text('Your email', style: AppTextStyles.label),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _sendOtp(),
                  decoration: InputDecoration(
                    hintText: 'you@example.com',
                    hintStyle: AppTextStyles.body.copyWith(color: AppColors.ink4),
                    filled: true,
                    fillColor: AppColors.field,
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.smAll,
                      borderSide: BorderSide(color: AppColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadii.smAll,
                      borderSide: BorderSide(color: AppColors.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadii.smAll,
                      borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _sendOtp,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: AppRadii.smAll),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Continue',
                            style: AppTextStyles.button
                                .copyWith(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: Divider(color: AppColors.line)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style:
                            AppTextStyles.caption.copyWith(color: AppColors.ink3)),
                  ),
                  Expanded(child: Divider(color: AppColors.line)),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.read<AuthCubit>().signInWithApple(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: AppRadii.smAll),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.apple, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Sign in with Apple',
                            style: AppTextStyles.button.copyWith(color: Colors.white)),
                      ],
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

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) return;
    setState(() => _loading = true);
    await context.read<AuthCubit>().verifyOtp(widget.email, code);
    if (mounted) setState(() => _loading = false);
    // Router's redirect listener handles navigation on AuthAuthenticated/AuthNeedsProfile.
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          elevation: 0,
          leading: BackButton(color: AppColors.ink),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text('Check your email', style: AppTextStyles.h1),
                const SizedBox(height: 8),
                Text(
                  'We sent a 6-digit code to ${widget.email}',
                  style: AppTextStyles.body.copyWith(color: AppColors.ink3),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 6,
                  onSubmitted: (_) => _verify(),
                  style: AppTextStyles.h1.copyWith(
                      letterSpacing: 8, fontSize: 28),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '······',
                    hintStyle: AppTextStyles.h1.copyWith(
                        letterSpacing: 8,
                        fontSize: 28,
                        color: AppColors.ink4),
                    filled: true,
                    fillColor: AppColors.field,
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.smAll,
                      borderSide: BorderSide(color: AppColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadii.smAll,
                      borderSide: BorderSide(color: AppColors.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadii.smAll,
                      borderSide:
                          BorderSide(color: AppColors.accent, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _verify,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: AppRadii.smAll),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Verify',
                            style: AppTextStyles.button
                                .copyWith(color: Colors.white)),
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
