/// Local, display-only wallet snapshot. In the real app this is populated
/// from `GET /positions/` plus a Solana RPC balance check — never from a
/// hand-entered value.
class WalletBalance {
  const WalletBalance({
    required this.address,
    required this.solBalance,
    required this.usdcBalance,
    required this.providerName,
  });

  final String address;
  final double solBalance;
  final double usdcBalance;
  final String providerName; // Phantom | Solflare | ...

  String get shortAddress {
    if (address.length <= 8) return address;
    return '${address.substring(0, 4)}…${address.substring(address.length - 4)}';
  }
}
