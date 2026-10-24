import 'package:flutter/material.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/callit_api.dart';
import '../../core/api/token_store.dart';
import '../../core/widgets/app_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../home/home_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key, required this.email});

  final String email;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;

  String get _code => _controllers.map((c) => c.text).join();

  void _submit() async {
    setState(() => _loading = true);
    try {
      final result = await callitApi.verify(email: widget.email, code: _code);
      final user = (result['user'] as Map?)?.cast<String, dynamic>();
      await TokenStore.instance.saveSession(
        token: result['token'] as String,
        userId: user?['id'] as String?,
        userName: user?['name'] as String?,
        userEmail: user?['email'] as String?,
      );
      // The account's Solana wallet is provisioned automatically — fetch it
      // now rather than making the person connect one. Best-effort: a
      // failure here shouldn't block sign-up, the wallet gets picked up
      // the next time something needs it.
      try {
        final address = (user?['walletAddress'] as String?) ?? await callitApi.fetchWalletAddress();
        if (address != null && address.isNotEmpty) {
          await TokenStore.instance.saveWallet(address: address, provider: 'Solana');
        }
      } catch (_) {}
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
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complete = _code.length == 6;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Check your email', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  style: AppTextStyles.subtitle,
                  children: [
                    const TextSpan(text: "We've sent a 6-digit code to "),
                    TextSpan(text: widget.email, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 44,
                    height: 56,
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: AppTextStyles.h3,
                      decoration: const InputDecoration(counterText: ''),
                      onChanged: (v) {
                        if (v.isNotEmpty && i < 5) {
                          _focusNodes[i + 1].requestFocus();
                        }
                        setState(() {});
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              AppButton(label: 'Verify', loading: _loading, onPressed: complete ? _submit : null),
              const SizedBox(height: 16),
              Center(
                child: TextButton(onPressed: () {}, child: const Text("Didn't get a code? Resend")),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
