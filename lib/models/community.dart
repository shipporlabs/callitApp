class Community {
  const Community({
    required this.id,
    required this.name,
    required this.slug,
    required this.attributionId,
    required this.creatorUserId,
    required this.marketCount,
    required this.volumeUsdc,
  });

  final String id;
  final String name;
  final String slug;
  final String attributionId;
  final String creatorUserId;
  final int marketCount;
  final double volumeUsdc;

  String get volumeLabel => '\$${volumeUsdc.toStringAsFixed(volumeUsdc >= 1000 ? 0 : 2)} USDC';

  factory Community.fromJson(Map<String, dynamic> json) {
    final vol = json['volumeUsdc'];
    final volNum = vol is num ? vol.toDouble() : (double.tryParse(vol?.toString() ?? '') ?? 0.0);
    return Community(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Community',
      slug: (json['slug'] as String?) ?? '',
      attributionId: (json['attributionId'] as String?) ?? '',
      creatorUserId: (json['creatorUserId'] as String?) ?? '',
      marketCount: (json['marketCount'] as num?)?.toInt() ?? 0,
      volumeUsdc: volNum,
    );
  }
}
