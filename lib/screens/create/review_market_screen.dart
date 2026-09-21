import 'package:flutter/material.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/pill_chip.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'market_created_screen.dart';

const _categories = ['Sports', 'Crypto', 'Politics', 'Entertainment', 'Finance', 'Science', 'World', 'Other'];

/// Step 2: the AI-compiled draft, editable before anything touches Panta.
/// A confidence flag calls out anything worth a second look — this is
/// where Callit earns trust before a creation fee is quoted.
class ReviewMarketScreen extends StatefulWidget {
  const ReviewMarketScreen({super.key, required this.rawInput});

  final String rawInput;

  @override
  State<ReviewMarketScreen> createState() => _ReviewMarketScreenState();
}

class _ReviewMarketScreenState extends State<ReviewMarketScreen> {
  late final TextEditingController _questionController;
  late final TextEditingController _ruleController;
  late final TextEditingController _sourceController;
  String _category = 'Sports';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Hook point: these three fields are what your AI compiler returns —
    // this screen just renders and lets the creator edit them.
    _questionController = TextEditingController(
      text: widget.rawInput.length > 8
          ? (widget.rawInput.startsWith('http') ? 'Will the linked event resolve YES?' : widget.rawInput)
          : 'Will the Super Eagles qualify for the 2027 World Cup?',
    );
    _ruleController = TextEditingController(
      text: 'Resolves YES if the official result confirms the outcome above by the close date; otherwise NO.',
    );
    _sourceController = TextEditingController(text: 'https://www.cafonline.com');
  }

  void _confirm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateSignSheet(onDone: () {
        Navigator.of(context).pop(); // close sheet
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => MarketCreatedScreen(question: _questionController.text)),
          (route) => route.isFirst,
        );
      }),
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
                color: AppColors.highlight.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.ink),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Callit drafted this from what you pasted. Check it over before it goes live.',
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
                        Text('In 1 hour', style: AppTextStyles.body(14, weight: FontWeight.w700)),
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
                        Text('Pick a date', style: AppTextStyles.body(14, weight: FontWeight.w700)),
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
}

/// Confirm the creation fee and simulate the quote → build → sign →
/// broadcast → register flow described in the Panta docs.
class _CreateSignSheet extends StatefulWidget {
  const _CreateSignSheet({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_CreateSignSheet> createState() => _CreateSignSheetState();
}

class _CreateSignSheetState extends State<_CreateSignSheet> {
  bool _signing = false;

  void _sign() async {
    setState(() => _signing = true);
    // Hook point: POST /markets/create/quote/ → /markets/create/build/ →
    // wallet sign → broadcast → /markets/register/.
    await Future.delayed(const Duration(milliseconds: 1500));
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
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
                _row('Creation fee', '— USDC'),
                const SizedBox(height: 10),
                _row('Network', 'Solana'),
                const SizedBox(height: 10),
                _row('Wallet', 'Connected'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The exact fee comes from a live quote before you sign — nothing is charged here.',
            style: AppTextStyles.caption,
          ),
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
