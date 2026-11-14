import 'api_client.dart';

/// One method per Callit API endpoint (see the OpenAPI spec this maps
/// to), grouped by the spec's own tags. Every method returns the
/// already-unwrapped `data` payload — [ApiClient] takes care of the
/// envelope and throws [ApiException] on failure, so callers just
/// `await` and `try`/`catch`.
class CallitApi {
  CallitApi._();
  static final CallitApi instance = CallitApi._();

  final _c = ApiClient.instance;

  // ---- Auth ----------------------------------------------------------

  /// Sign up. Sends a 6-digit code to [email]; call [verify] with it.
  Future<Map<String, dynamic>> register({required String name, required String email, required String password}) async {
    final data = await _c.post('/auth/register', auth: false, body: {'name': name, 'email': email, 'password': password});
    return (data as Map?)?.cast<String, dynamic>() ?? {};
  }

  /// Confirms the 6-digit email code and returns `{user, token}`.
  Future<Map<String, dynamic>> verify({required String email, required String code}) async {
    final data = await _c.post('/auth/verify', auth: false, body: {'email': email, 'code': code});
    return (data as Map).cast<String, dynamic>();
  }

  /// Logs in with email + password.
  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final data = await _c.post('/auth/login', auth: false, body: {'email': email, 'password': password});
    return (data as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<Map<String, dynamic>> me() async {
    final data = await _c.get('/me');
    return (data as Map?)?.cast<String, dynamic>() ?? {};
  }

  /// FossaPay provisions a Solana wallet automatically for every account —
  /// there's no "connect a wallet" step in this app. Reads it off the
  /// signed-in user's profile; call this right after sign-up/login (and
  /// defensively on app start for an older cached session) and cache the
  /// result in [TokenStore].
  Future<String?> fetchWalletAddress() async {
    final data = await me();
    final address = data['walletAddress'] as String?;
    return (address != null && address.isNotEmpty) ? address : null;
  }

  // ---- Markets ---------------------------------------------------------

  /// Market catalog. [category]/[status] are the API's lowercase enum
  /// values (`sports`, `crypto`, … / `primary`, `secondary`, …).
  Future<Map<String, dynamic>> listMarkets({String? category, String? status, String? createdBy, String? cursor, int limit = 20}) async {
    final data = await _c.get('/markets', auth: false, query: {
      if (category != null) 'category': category,
      if (status != null) 'status': status,
      if (createdBy != null) 'createdBy': createdBy,
      if (cursor != null) 'cursor': cursor,
      'limit': limit,
    });
    return (data as Map?)?.cast<String, dynamic>() ?? {'items': [], 'nextCursor': null};
  }

  Future<Map<String, dynamic>> getMarket(String id) async {
    final data = await _c.get('/markets/$id', auth: false);
    return (data as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> getMarketTrades(String id) async {
    final data = await _c.get('/markets/$id/trades', auth: false);
    if (data is List) return data;
    return (data as Map?)?['items'] as List<dynamic>? ?? [];
  }

  /// The fixed 8-value category enum, straight from the server — falls
  /// back to the spec's own list if the call fails, so the filter chips
  /// never come up empty.
  static const fallbackCategories = ['sports', 'crypto', 'politics', 'entertainment', 'finance', 'science', 'world', 'other'];

  Future<List<String>> categories() async {
    final data = await _c.get('/categories', auth: false);
    if (data is List) return data.map((e) => e.toString()).toList();
    return fallbackCategories;
  }

  // ---- AI Compiler -------------------------------------------------

  /// Step 1 of "paste a take": returns a Panta-shaped draft plus the
  /// start/end/resolution timestamps to carry into [createQuote].
  Future<Map<String, dynamic>> compile(String text) async {
    final data = await _c.post('/ai/compile', body: {'text': text});
    return (data as Map).cast<String, dynamic>();
  }

  // ---- Create market -------------------------------------------------

  Future<Map<String, dynamic>> createImageUploadSignature() async {
    final data = await _c.post('/markets/create/image-upload');
    return (data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> createQuote({
    required String wallet,
    required String question,
    required String resolutionRule,
    required List<String> sourcesOfTruth,
    required String category,
    required int startTime,
    required int endTime,
    required int resolutionTime,
    String? imageUrl,
    String marketType = 'standard',
    bool eventInProgress = false,
    String? communityId,
  }) async {
    final data = await _c.post('/markets/create/quote', body: {
      'wallet': wallet,
      'question': question,
      'resolutionRule': resolutionRule,
      'sourcesOfTruth': sourcesOfTruth,
      'category': category,
      'startTime': startTime,
      'endTime': endTime,
      'resolutionTime': resolutionTime,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'marketType': marketType,
      'eventInProgress': eventInProgress,
      if (communityId != null) 'communityId': communityId,
    });
    return (data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> createBuild({required String createId, String? wallet}) async {
    final data = await _c.post('/markets/create/build', body: {'createId': createId, if (wallet != null) 'wallet': wallet});
    return (data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> createRegister({required String createId, required String signature}) async {
    final data = await _c.post('/markets/create/register', body: {'createId': createId, 'signature': signature});
    return (data as Map).cast<String, dynamic>();
  }

  // ---- Orders (buy flow) ---------------------------------------------

  Future<Map<String, dynamic>> orderQuote({required String wallet, required String marketId, required bool side, required String amountUsdc, String? communityId}) async {
    final data = await _c.post('/orders/quote', body: {
      'wallet': wallet,
      'marketId': marketId,
      'side': side ? 'yes' : 'no',
      'amountUsdc': amountUsdc,
      if (communityId != null) 'communityId': communityId,
    });
    return (data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> orderBuild({required String quoteId, required String wallet, String? communityId, int maxSlippageBps = 100}) async {
    final data = await _c.post('/orders/build', body: {
      'quoteId': quoteId,
      'wallet': wallet,
      if (communityId != null) 'communityId': communityId,
      'maxSlippageBps': maxSlippageBps,
    });
    return (data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> orderSubmit({required String orderId, required String signature}) async {
    final data = await _c.post('/orders/submit', body: {'orderId': orderId, 'signature': signature});
    return (data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> orderVerify({required String orderId, String? signature}) async {
    final data = await _c.post('/orders/verify', body: {'orderId': orderId, if (signature != null) 'signature': signature});
    return (data as Map).cast<String, dynamic>();
  }

  // ---- Positions & claims ----------------------------------------------

  Future<List<dynamic>> positions(String wallet) async {
    final data = await _c.get('/positions', query: {'wallet': wallet});
    return (data as Map?)?['positions'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> claimWin({required String wallet, required String marketId}) async {
    final data = await _c.post('/claims/win', body: {'wallet': wallet, 'marketId': marketId});
    return (data as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<Map<String, dynamic>> claimCreatorFees({required String wallet, required String marketId}) async {
    final data = await _c.post('/claims/creator-fees', body: {'wallet': wallet, 'marketId': marketId});
    return (data as Map?)?.cast<String, dynamic>() ?? {};
  }

  // ---- Trades (attribution) -------------------------------------------

  Future<Map<String, dynamic>> reportTrade({required String signature, required String wallet, required String marketId, String? quoteId, String? communityId}) async {
    final data = await _c.post('/trades/report', body: {
      'signature': signature,
      'wallet': wallet,
      'marketId': marketId,
      if (quoteId != null) 'quoteId': quoteId,
      if (communityId != null) 'communityId': communityId,
    });
    return (data as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<Map<String, dynamic>> tradeStatus(String signature) async {
    final data = await _c.get('/trades/$signature');
    return (data as Map?)?.cast<String, dynamic>() ?? {};
  }

  // ---- Communities -------------------------------------------------

  Future<Map<String, dynamic>> createCommunity(String name) async {
    final data = await _c.post('/communities', body: {'name': name});
    return (data as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> communities() async {
    final data = await _c.get('/communities', auth: false);
    return (data as Map?)?['items'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> community(String id) async {
    final data = await _c.get('/communities/$id', auth: false);
    return (data as Map?)?.cast<String, dynamic>() ?? {};
  }

  // ---- Creator dashboard -----------------------------------------------

  Future<List<dynamic>> myMarkets() async {
    final data = await _c.get('/me/markets');
    if (data is List) return data;
    return (data as Map?)?['items'] as List<dynamic>? ?? [];
  }

  // ---- Share cards -----------------------------------------------------

  Future<Map<String, dynamic>> createShareCard(String marketId) async {
    final data = await _c.post('/share-card', body: {'marketId': marketId});
    return (data as Map?)?.cast<String, dynamic>() ?? {};
  }

  // ---- Wallet funding (FossaPay NGN → USDC) ---------------------------
  //
  // NOTE: no OpenAPI spec was supplied for these three endpoints — the
  // paths, field names and response shapes below are inferred from how
  // `fund_wallet_screen.dart` and `wallet_screen.dart` consume them.
  // Verify these against the real FossaPay-backed Callit backend and
  // adjust the path/field names here if they differ; everything else in
  // the two screens is written to be tolerant of minor shape changes.

  /// Starts an NGN→USDC deposit: creates a FossaPay virtual/bank transfer
  /// checkout for [amountNgn] that will credit [walletAddress] with USDC
  /// once paid. Expected response fields: `reference`, `bankName`,
  /// `accountNumber`, `accountName`, `amountPayableNgn` (or `amountNgn`).
  Future<Map<String, dynamic>> createFundingCheckout({required double amountNgn, required String walletAddress}) async {
    final data = await _c.post('/funding/checkout', body: {
      'amountNgn': amountNgn,
      'walletAddress': walletAddress,
    });
    return (data as Map?)?.cast<String, dynamic>() ?? {};
  }

  /// Polls a funding checkout's status by its [reference]. Expected
  /// response field: `status` (`'pending'` | `'completed'` | `'failed'`).
  Future<Map<String, dynamic>> getFundingStatus(String reference) async {
    final data = await _c.get('/funding/status', query: {'reference': reference});
    return (data as Map?)?.cast<String, dynamic>() ?? {};
  }

  /// Trade history for a wallet (distinct from [positions], which is
  /// current holdings) — used for the "Recent trades" list on the wallet
  /// screen and on each market's "Recent activity" section.
  Future<List<dynamic>> getWalletTrades(String wallet) async {
    final data = await _c.get('/wallets/$wallet/trades');
    if (data is List) return data;
    return (data as Map?)?['items'] as List<dynamic>? ?? [];
  }

  // ---- NEAR Intents & AI Truth Consensus (NEAR Hackathon) -------------

  /// Retrieves supported cross-chain tokens from NEAR Intents (1Click).
  Future<List<dynamic>> fetchNearTokens() async {
    final data = await _c.get('/near/tokens', auth: false);
    if (data is List) return data;
    return (data as Map?)?['data'] as List<dynamic>? ?? [];
  }

  /// Obtains a guaranteed cross-chain swap quote and single-use deposit address
  /// powered by NEAR Intents / Defuse Protocol.
  Future<Map<String, dynamic>> createNearIntentQuote({
    required String originAsset,
    required String amount,
    String? recipient,
    String? destinationAsset,
    String? refundTo,
    bool dry = false,
  }) async {
    final data = await _c.post('/near/deposit/quote', body: {
      'originAsset': originAsset,
      'amount': amount,
      if (recipient != null && recipient.isNotEmpty) 'recipient': recipient,
      if (destinationAsset != null) 'destinationAsset': destinationAsset,
      if (refundTo != null && refundTo.isNotEmpty) 'refundTo': refundTo,
      'dry': dry,
    });
    return (data as Map?)?.cast<String, dynamic>() ?? {};
  }

  /// SOL and USDC balances for a wallet, read by the backend. Browsers cannot
  /// call Solana's public RPC directly (it answers 403), so the app asks here.
  Future<Map<String, dynamic>> getWalletBalances(String wallet, {bool fresh = false}) async {
    final data = await _c.get('/wallets/$wallet/balances', query: fresh ? {'fresh': '1'} : null, auth: false);
    return (data as Map?)?.cast<String, dynamic>() ?? {};
  }

  /// Polls status of a NEAR Intents deposit by its [depositAddress].
  Future<Map<String, dynamic>> getNearDepositStatus(String depositAddress) async {
    final data = await _c.get('/near/deposit/status', query: {'depositAddress': depositAddress}, auth: false);
    return (data as Map?)?.cast<String, dynamic>() ?? {};
  }

  /// Fetches the dynamic AI-synthesized Truth Consensus encyclopedia entry
  /// for a market (Illia Polosukhin's hackathon benchmark thesis).
  Future<Map<String, dynamic>> fetchTruthConsensus(String marketId) async {
    final data = await _c.get('/markets/$marketId/truth-consensus', auth: false);
    return (data as Map?)?.cast<String, dynamic>() ?? {};
  }
}

/// Convenience accessor — `callitApi.listMarkets(...)` reads a little
/// better at call sites than the singleton's full name.
final callitApi = CallitApi.instance;
