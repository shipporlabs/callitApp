import 'package:flutter/material.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/callit_api.dart';
import '../../core/api/token_store.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/app_text_field.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../home/home_screen.dart';
import 'sign_up_screen.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  void _submit() async {
    setState(() => _loading = true);
    try {
      final result = await callitApi.login(email: _emailController.text.trim(), password: _passwordController.text);
      final token = result['token'] as String?;
      if (token == null) {
        throw ApiException(statusCode: 0, code: 'NO_TOKEN', message: 'Login succeeded but no session token came back.');
      }
      final user = (result['user'] as Map?)?.cast<String, dynamic>();
      await TokenStore.instance.saveSession(
        token: token,
        userId: user?['id'] as String?,
        userName: user?['name'] as String?,
        userEmail: user?['email'] as String? ?? _emailController.text.trim(),
      );
      // In case this is a fresh device/install without the wallet cached
      // locally — the account's FossaPay wallet already exists server-side.
      if (!TokenStore.instance.hasWallet) {
        try {
          final address = await callitApi.fetchWalletAddress();
          if (address != null) {
            await TokenStore.instance.saveWallet(address: address, provider: 'FossaPay');
          }
        } catch (_) {}
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _emailController.text.contains('@') && _passwordController.text.isNotEmpty;
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
              Text('Welcome back', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text('Log in to keep trading and tracking your markets.', style: AppTextStyles.subtitle),
              const SizedBox(height: 32),
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
                hint: 'Your password',
                controller: _passwordController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                onChanged: (_) => setState(() {}),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () {}, child: const Text('Forgot password?')),
              ),
              const SizedBox(height: 16),
              AppButton(label: 'Log in', loading: _loading, onPressed: canSubmit ? _submit : null),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.body(14, color: AppColors.slate),
                      children: const [
                        TextSpan(text: "Don't have an account? "),
                        TextSpan(text: 'Sign up', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
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
