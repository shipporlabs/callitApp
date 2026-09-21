import 'package:flutter/material.dart';
import '../../core/widgets/app_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'review_market_screen.dart';

/// Step 1 of Callit's core flow: paste a headline, a tweet, or a raw
/// question. The next screen is where the AI-compiled draft is reviewed
/// before anything is quoted against Panta.
class PasteScreen extends StatefulWidget {
  const PasteScreen({super.key});

  @override
  State<PasteScreen> createState() => _PasteScreenState();
}

class _PasteScreenState extends State<PasteScreen> {
  final _controller = TextEditingController();
  bool _compiling = false;

  static const _examples = [
    'Will the Super Eagles qualify for the 2027 World Cup?',
    'https://x.com/someone/status/123456789',
    'Will SOL flip \$300 before March?',
  ];

  void _compile() async {
    setState(() => _compiling = true);
    // Hook point: send `_controller.text` to your AI compiler, which
    // returns a draft matching Panta's create schema (question,
    // resolutionRule, sourcesOfTruth, category, times, imageUrl).
    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReviewMarketScreen(rawInput: _controller.text)),
    );
    setState(() => _compiling = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text('New market', style: AppTextStyles.h3),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Paste any take', style: AppTextStyles.h1.copyWith(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                'A headline, a tweet link, or your own question. Callit turns it into a live market.',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.mist),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 6,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.body(16, weight: FontWeight.w500),
                  decoration: const InputDecoration(
                    hintText: 'Paste a headline, tweet link, or type a question…',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(18),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.content_paste_rounded, size: 16),
                  label: const Text('Paste from clipboard'),
                ),
              ),
              const SizedBox(height: 12),
              Text('Try one of these', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _examples.map((e) {
                  return ActionChip(
                    label: Text(e, overflow: TextOverflow.ellipsis),
                    onPressed: () => setState(() => _controller.text = e),
                  );
                }).toList(),
              ),
              const Spacer(),
              AppButton(
                label: 'Compile market',
                icon: Icons.auto_awesome_rounded,
                loading: _compiling,
                onPressed: _controller.text.trim().isEmpty ? null : _compile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
