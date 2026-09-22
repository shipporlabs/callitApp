import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/callit_api.dart';
import '../../core/api/token_store.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/pill_chip.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../wallet/add_wallet_screen.dart';
import 'market_created_screen.dart';

const _categories = ['Sports', 'Crypto', 'Politics', 'Entertainment', 'Finance', 'Science', 'World', 'Other'];

/// Step 2: the AI-compiled draft, editable before anything touches Panta.
/// [compiled] is `POST /ai/compile`'s response (draft + start/end/
/// resolution timestamps) when the compiler call in `PasteScreen`
/// succeeded; when it's null (offline, or the compiler errored) this
/// falls back to a locally-guessed draft so the flow still completes.
class ReviewMarketScreen extends StatefulWidget {
  const ReviewMarketScreen({super.key, required this.rawInput, this.compiled});

  final String rawInput;
  final Map<String, dynamic>? compiled;

  @override
  State<ReviewMarketScreen> createState() => _ReviewMarketScreenState();
}

class _ReviewMarketScreenState extends State<ReviewMarketScreen> {
  late final TextEditingController _questionController;
  late final TextEditingController _ruleController;
  late final TextEditingController _sourceController;
  late String _category;
  late int _startTime;
  late int _endTime;
  late int _resolutionTime;
  late String _marketType;
  late bool _eventInProgress;
  bool _ambiguous = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final draft = (widget.compiled?['draft'] as Map?)?.cast<String, dynamic>();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    _questionController = TextEditingController(
      text: (draft?['question'] as String?) ??
          (widget.rawInput.length > 8
              ? (widget.rawInput.startsWith('http') ? 'Will the linked event resolve YES?' : widget.rawInput)
              : 'Will the Super Eagles qualify for the 2027 World Cup?'),
    );
    _ruleController = TextEditingController(
      text: (draft?['resolutionRule'] as String?) ??
          'Resolves YES if the official result confirms the outcome above by the close date; otherwise NO.',
    );
    final sources = (draft?['sourcesOfTruth'] as List?)?.cast<String>();
    _sourceController = TextEditingController(text: sources?.isNotEmpty == true ? sources!.first : 'https://www.cafonline.com');

    final rawCategory = draft?['category'] as String?;
    _category = rawCategory != null && rawCategory.isNotEmpty
        ? rawCategory[0].toUpperCase() + rawCategory.substring(1)
        : 'Sports';
    if (!_categories.contains(_category)) _category = 'Sports';

    _startTime = (widget.compiled?['startTime'] as int?) ?? now + 3600;
    _endTime = (widget.compiled?['endTime'] as int?) ?? now + 3600 * 6;
    _resolutionTime = (widget.compiled?['resolutionTime'] as int?) ?? now + 3600 * 8;
    _marketType = (draft?['marketType'] as String?) ?? 'standard';
    _eventInProgress = (draft?['eventInProgress'] as bool?) ?? false;
    _ambiguous = (draft?['ambiguous'] as bool?) ?? false;
  }

  Future<void> _confirm() async {
    if (!TokenStore.instance.hasWallet) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddWalletScreen()));
      if (!mounted || !TokenStore.instance.hasWallet) return;
    }

    setState(() => _submitting = true);
    Map<String, dynamic> quote;
    try {
      quote = await callitApi.createQuote(
        wallet: TokenStore.instance.walletAddress!,
        question: _questionController.text.trim(),
        resolutionRule: _ruleController.text.trim(),
        sourcesOfTruth: [_sourceController.text.trim()],
        category: _category.toLowerCase(),
        startTime: _startTime,
        endTime: _endTime,
        resolutionTime: _resolutionTime,
        marketType: _marketType,
        eventInProgress: _eventInProgress,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateSignSheet(
        quote: quote,
        onDone: (marketId) {
          Navigator.of(context).pop(); // close sheet
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => MarketCreatedScreen(question: _questionController.text, marketId: marketId)),
            (route) => route.isFirst,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _ruleController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(leading: const BackButton(), title: Text('Review market', style: AppTextStyles.h3)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (_ambiguous ? AppColors.no : AppColors.highlight).withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(_ambiguous ? Icons.warning_amber_rounded : Icons.auto_awesome_rounded, size: 18, color: AppColors.ink),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _ambiguous
                          ? "Callit's compiler flagged this question as ambiguous — tighten the resolution rule before you sign."
                          : 'Callit drafted this from what you pasted. Check it over before it goes live.',
                      style: AppTextStyles.body(13, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(label: 'Question', controller: _questionController, maxLines: 2),
            const SizedBox(height: 18),
            Text('Category', style: AppTextStyles.body(14, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) {
                final selected = c == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: PillChip(
                    label: c,
                    background: selected ? AppColors.ink : AppColors.mist,
                    foreground: selected ? AppColors.paper : AppColors.ink,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            AppTextField(label: 'Resolution rule', controller: _ruleController, maxLines: 3),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Source of truth',
              controller: _sourceController,
              prefixIcon: Icons.link_rounded,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.mist), borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Starts', style: AppTextStyles.caption),
                        const SizedBox(height: 4),
                        Text(_relativeLabel(_startTime), style: AppTextStyles.body(14, weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.mist), borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resolves', style: AppTextStyles.caption),
                        const SizedBox(height: 4),
                        Text(_relativeLabel(_resolutionTime), style: AppTextStyles.body(14, weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            AppButton(label: 'Continue', loading: _submitting, onPressed: _confirm),
          ],
        ),
      ),
    );
  }

  String _relativeLabel(int epochSeconds) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diffHours = ((epochSeconds - now) / 3600).round();
    if (diffHours <= 0) return 'Now';
    if (diffHours < 24) return 'In $diffHours ${diffHours == 1 ? 'hour' : 'hours'}';
    return 'In ${(diffHours / 24).round()} days';
  }
}

/// Confirms the live creation-fee quote and runs quote → build → sign →
/// register against the real Callit API.
class _CreateSignSheet extends StatefulWidget {
  const _CreateSignSheet({required this.quote, required this.onDone});

  final Map<String, dynamic> quote;
  final void Function(String marketId) onDone;

  @override
  State<_CreateSignSheet> createState() => _CreateSignSheetState();
}

class _CreateSignSheetState extends State<_CreateSignSheet> {
  bool _signing = false;
  String? _error;

  void _sign() async {
    setState(() {
      _signing = true;
      _error = null;
    });
    try {
      final wallet = TokenStore.instance.walletAddress!;
      final createId = widget.quote['createId'] as String;
      final build = await callitApi.createBuild(createId: createId, wallet: wallet);

      // Hook point: hand `build['transaction']` (base64) to Solana Mobile
      // Wallet Adapter for the user's real signature. Simulated here.
      await Future.delayed(const Duration(milliseconds: 900));
      final signature = _mockSignature();

      final registered = await callitApi.createRegister(createId: createId, signature: signature);
      widget.onDone(registered['marketId'] as String? ?? '');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _signing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong creating that market.';
        _signing = false;
      });
    }
  }

  String _mockSignature() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz123456789';
    final rand = Random();
    return List.generate(64, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final feeUsdc = (int.tryParse(widget.quote['paymentUsdc']?.toString() ?? '') ?? 0) / 1000000;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: const BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: AppColors.mist, borderRadius: BorderRadius.circular(999)),
            ),
          ),
          Text('Confirm and sign', style: AppTextStyles.h2),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.mist), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _row('Creation fee', '${feeUsdc.toStringAsFixed(2)} USDC'),
                const SizedBox(height: 10),
                _row('Network', 'Solana'),
                const SizedBox(height: 10),
                _row('Wallet', TokenStore.instance.walletAddress != null
                    ? '${TokenStore.instance.walletAddress!.substring(0, 4)}…${TokenStore.instance.walletAddress!.substring(TokenStore.instance.walletAddress!.length - 4)}'
                    : 'Connected'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is a live quote from Panta — it expires a minute or so after being issued, so sign promptly.',
            style: AppTextStyles.caption,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: AppTextStyles.body(13, color: AppColors.no, weight: FontWeight.w600)),
          ],
          const SizedBox(height: 20),
          AppButton(label: 'Sign in wallet', loading: _signing, onPressed: _signing ? null : _sign),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body(14, color: AppColors.slate)),
        Text(value, style: AppTextStyles.tabularNums(14)),
      ],
    );
  }
}
