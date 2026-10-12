/// A Callit community — a private leaderboard/attribution group markets
/// can be created or traded under (see the `/communities` endpoints in
/// `CallitApi`). The API's exact response shape isn't pinned down by a
/// spec, so every field here is read defensively with sane fallbacks.
class Community {
  const Community({
    required this.id,
    required this.name,
    required this.slug,
    required this.marketCount,
    required this.volumeUsdc,
    required this.attributionId,
    this.memberCount,
  });

  final String id;
  final String name;
  final String slug;
  final int marketCount;
  final double volumeUsdc;
  final String attributionId;
  final int? memberCount;

  /// Display-ready trading volume, e.g. "$1,234".
  String get volumeLabel => '\$${volumeUsdc.toStringAsFixed(volumeUsdc >= 1000 ? 0 : 2)}';

  factory Community.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['communityId'])?.toString() ?? '';
    final name = (json['name'] as String?) ?? 'Community';

    final rawSlug = json['slug'] as String?;
    final slug = (rawSlug != null && rawSlug.isNotEmpty)
        ? rawSlug
        : name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');

    final marketCountRaw = json['marketCount'] ?? json['marketsCount'] ?? json['markets'];
    final marketCount = marketCountRaw is num
        ? marketCountRaw.toInt()
        : (marketCountRaw is List ? marketCountRaw.length : 0);

    final volumeRaw = json['volumeUsdc'] ?? json['volume'] ?? json['totalVolume'];
    final volumeUsdc = volumeRaw is num ? volumeRaw.toDouble() : double.tryParse(volumeRaw?.toString() ?? '') ?? 0.0;

    final memberRaw = json['memberCount'] ?? json['members'];
    final memberCount = memberRaw is num ? memberRaw.toInt() : int.tryParse(memberRaw?.toString() ?? '');

    return Community(
      id: id,
      name: name,
      slug: slug,
      marketCount: marketCount,
      volumeUsdc: volumeUsdc,
      attributionId: (json['attributionId'] as String?) ?? id,
      memberCount: memberCount,
    );
  }
}
