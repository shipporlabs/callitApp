import 'package:flutter/material.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/app_text_field.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'log_in_screen.dart';
import 'verify_otp_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _agreed = false;

  void _submit() async {
    setState(() => _loading = true);
    // Hook point: call your auth backend / Panta account register here.
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VerifyOtpScreen(email: _emailController.text)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _nameController.text.isNotEmpty &&
        _emailController.text.contains('@') &&
        _passwordController.text.length >= 8 &&
        _agreed;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLogo(size: 30),
              const SizedBox(height: 24),
              Text('Create your account', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text(
                'Takes about a minute. You can connect a wallet after.',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 32),
              AppTextField(
                label: 'Full name',
                hint: 'Gideon Jones',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Email',
                hint: 'you@email.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Password',
                hint: 'At least 8 characters',
                controller: _passwordController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              InkWell(
                onTap: () => setState(() => _agreed = !_agreed),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                      activeColor: AppColors.ink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          'I agree to the Terms of Use and confirm markets I trade are lawful where I live.',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              AppButton(
                label: 'Continue',
                loading: _loading,
                onPressed: canSubmit ? _submit : null,
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LogInScreen()),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.body(14, color: AppColors.slate),
                      children: const [
                        TextSpan(text: 'Already have an account? '),
                        TextSpan(text: 'Log in', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
