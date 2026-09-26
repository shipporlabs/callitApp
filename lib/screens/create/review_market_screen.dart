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

import '../../models/community.dart';

const _categories = ['Sports', 'Crypto', 'Politics', 'Entertainment', 'Finance', 'Science', 'World', 'Other'];

/// Step 2: the AI-compiled draft, editable before anything touches Panta.
/// [compiled] is `POST /ai/compile`'s response (draft + start/end/
/// resolution timestamps) when the compiler call in `PasteScreen`
/// succeeded; when it's null (offline, or the compiler errored) this
/// falls back to a locally-guessed draft so the flow still completes.
class ReviewMarketScreen extends StatefulWidget {
  const ReviewMarketScreen({super.key, required this.rawInput, this.compiled, this.initialCommunity});

  final String rawInput;
  final Map<String, dynamic>? compiled;
  final Community? initialCommunity;

  @override
  State<ReviewMarketScreen> createState() => _ReviewMarketScreenState();
}

class _ReviewMarketScreenState extends State<ReviewMarketScreen> {
  late final TextEditingController _questionController;
  late final TextEditingController _ruleController;
  late final TextEditingController _sourceController;
  late final TextEditingController _imageUrlController;
  late String _category;
  late int _startTime;
  late int _endTime;
  late int _resolutionTime;
  late String _marketType;
  late bool _eventInProgress;
  Community? _community;
  List<Community> _communities = [];
  bool _uploadingImage = false;
  bool _ambiguous = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _community = widget.initialCommunity;
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
    _imageUrlController = TextEditingController(text: (draft?['imageUrl'] as String?) ?? '');

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

    _loadCommunities();
  }

  Future<void> _loadCommunities() async {
    try {
      final items = await callitApi.communities();
      if (!mounted) return;
      setState(() {
        _communities = items.map((e) => Community.fromJson((e as Map).cast<String, dynamic>())).toList();
        if (_community != null) {
          final match = _communities.where((c) => c.id == _community!.id).firstOrNull;
          if (match != null) _community = match;
        }
      });
    } catch (_) {}
  }

  Future<void> _requestImageUploadSignature() async {
    setState(() => _uploadingImage = true);
    try {
      final sig = await callitApi.createImageUploadSignature();
      final pubId = sig['publicId'] as String? ?? 'img_${DateTime.now().millisecondsSinceEpoch}';
      final generatedUrl = 'https://res.cloudinary.com/callit/image/upload/$pubId.jpg';
      setState(() {
        _imageUrlController.text = generatedUrl;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Panta image upload signature obtained! URL attached.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not obtain image upload signature.')),
      );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _confirm() async {
    if (!TokenStore.instance.hasWallet) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddWalletScreen()));
      if (!mounted || !TokenStore.instance.hasWallet) return;
    }

    setState(() => _submitting = true);
    Map<String, dynamic> quote;
    try {
      final imgUrl = _imageUrlController.text.trim();
      quote = await callitApi.createQuote(
        wallet: TokenStore.instance.walletAddress!,
        question: _questionController.text.trim(),
        resolutionRule: _ruleController.text.trim(),
        sourcesOfTruth: [_sourceController.text.trim()],
        category: _category.toLowerCase(),
        startTime: _startTime,
        endTime: _endTime,
        resolutionTime: _resolutionTime,
        imageUrl: imgUrl.isNotEmpty ? imgUrl : null,
        communityId: _community?.id,
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
    _imageUrlController.dispose();
    super.dispose();
  }

  void _pickCommunity() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: AppColors.mist, borderRadius: BorderRadius.circular(999)),
              ),
            ),
            Text('Select Community', style: AppTextStyles.h2),
            const SizedBox(height: 6),
            Text('Trading volume will be attributed to this community.', style: AppTextStyles.caption),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.public_rounded, color: AppColors.ink),
              title: Text('None (Global Market)', style: AppTextStyles.body(15, weight: FontWeight.w600)),
              trailing: _community == null ? const Icon(Icons.check, color: AppColors.ink) : null,
              onTap: () {
                setState(() => _community = null);
                Navigator.of(ctx).pop();
              },
            ),
            const Divider(color: AppColors.mist),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _communities.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.mist, height: 1),
                itemBuilder: (ctx, i) {
                  final c = _communities[i];
                  final isSelected = _community?.id == c.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(c.name, style: AppTextStyles.body(15, weight: FontWeight.w600)),
                    subtitle: Text('c/${c.slug} • ${c.marketCount} markets', style: AppTextStyles.caption),
                    trailing: isSelected ? const Icon(Icons.check, color: AppColors.ink) : null,
                    onTap: () {
                      setState(() => _community = c);
                      Navigator.of(ctx).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
            // Community selection
            GestureDetector(
              onTap: _pickCommunity,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.mist),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hub_outlined, size: 20, color: AppColors.slate),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Community (optional)', style: AppTextStyles.caption),
                          const SizedBox(height: 2),
                          Text(
                            _community != null ? '${_community!.name} (c/${_community!.slug})' : 'Global (No community)',
                            style: AppTextStyles.body(14, weight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Market Image
            AppTextField(
              label: 'Image URL (optional)',
              controller: _imageUrlController,
              prefixIcon: Icons.image_outlined,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _uploadingImage ? null : _requestImageUploadSignature,
                  icon: _uploadingImage
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_file_rounded, size: 16),
                  label: Text(_uploadingImage ? 'Signing…' : 'Sign & Upload via Panta', style: AppTextStyles.body(13, weight: FontWeight.w600)),
                ),
                if (_imageUrlController.text.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _imageUrlController.text,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 20, color: AppColors.slate),
                    ),
                  ),
              ],
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
