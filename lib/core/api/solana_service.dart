import 'dart:convert';

import 'package:http/http.dart' as http;

/// On-chain balances for a Solana wallet: native SOL plus the USDC SPL
/// token (Callit's trading asset), and a rough combined USD estimate.
///
/// [totalUsdValue] is SOL-at-a-fixed-price + USDC (USDC ≈ $1). The SOL
/// price here is a static placeholder — swap `_solUsdPrice` for a real
/// price feed (Jupiter price API, Pyth, etc.) when wiring this up for
/// real, since a stale hardcoded price will under/overstate SOL's value.
class SolanaBalances {
  const SolanaBalances({required this.solBalance, required this.usdcBalance, required this.totalUsdValue});

  final double solBalance;
  final double usdcBalance;
  final double totalUsdValue;

  static const zero = SolanaBalances(solBalance: 0, usdcBalance: 0, totalUsdValue: 0);
}

/// Reads real on-chain balances over Solana's public JSON-RPC — no
/// wallet signature needed, since balances are public. Uses the public
/// mainnet-beta RPC endpoint by default; swap [rpcUrl] for a paid RPC
/// provider (Helius, QuickNode, etc.) before shipping, as the public
/// endpoint is rate-limited and not meant for production traffic.
class SolanaService {
  SolanaService._();
  static final SolanaService instance = SolanaService._();

  static const String rpcUrl = 'https://api.mainnet-beta.solana.com';

  /// Circulating-supply USDC mint on Solana mainnet.
  static const String _usdcMint = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v';

  /// Placeholder SOL/USD price — see class doc. Used only to roll SOL
  /// into [SolanaBalances.totalUsdValue]; USDC itself is treated as $1.
  static const double _solUsdPrice = 150.0;

  Future<dynamic> _rpc(String method, List<dynamic> params) async {
    final res = await http
        .post(
          Uri.parse(rpcUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': method, 'params': params}),
        )
        .timeout(const Duration(seconds: 12));
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded.containsKey('error')) {
      throw Exception((decoded['error'] as Map?)?['message'] ?? 'Solana RPC error');
    }
    return decoded['result'];
  }

  /// Fetches SOL + USDC balances for [wallet] (a base58 public key).
  /// Best-effort: on any RPC failure (bad address, network issue, rate
  /// limit) this returns [SolanaBalances.zero] rather than throwing, so a
  /// flaky public RPC never blocks the wallet screen from rendering.
  Future<SolanaBalances> getBalances(String wallet) async {
    try {
      final solFuture = _rpc('getBalance', [wallet]);
      final tokenFuture = _rpc('getTokenAccountsByOwner', [
        wallet,
        {'mint': _usdcMint},
        {'encoding': 'jsonParsed'},
      ]);

      final solResult = await solFuture;
      final tokenResult = await tokenFuture;

      final lamports = (solResult is Map ? solResult['value'] : solResult) as int? ?? 0;
      final sol = lamports / 1000000000; // 1 SOL = 1e9 lamports

      double usdc = 0;
      final accounts = (tokenResult as Map?)?['value'] as List<dynamic>? ?? [];
      for (final acc in accounts) {
        final info = acc['account']?['data']?['parsed']?['info'];
        final amount = info?['tokenAmount']?['uiAmount'];
        if (amount is num) usdc += amount.toDouble();
      }

      return SolanaBalances(
        solBalance: sol,
        usdcBalance: usdc,
        totalUsdValue: sol * _solUsdPrice + usdc,
      );
    } catch (_) {
      return SolanaBalances.zero;
    }
  }
}
