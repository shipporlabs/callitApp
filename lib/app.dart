import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'core/api/callit_api.dart';
import 'models/market.dart';
import 'screens/home/market_detail_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

/// A shared market link looks like `callit.my/<marketId>`. On the web the
/// server rewrites it to the app, so the id is the first path segment.
String? _sharedMarketId() {
  if (!kIsWeb) return null;
  final segs = Uri.base.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segs.length != 1) return null;
  final id = segs.first;
  return RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,44}$').hasMatch(id) ? id : null;
}

class CallitApp extends StatefulWidget {
  const CallitApp({super.key});

  @override
  State<CallitApp> createState() => _CallitAppState();
}

class _CallitAppState extends State<CallitApp> {
  @override
  void initState() {
    super.initState();
    final id = _sharedMarketId();
    if (id != null) _openShared(id);
  }

  Future<void> _openShared(String id) async {
    // Let the splash route first, then open the shared market on top.
    await Future.delayed(const Duration(milliseconds: 2200));
    try {
      final json = await callitApi.getMarket(id);
      final market = Market.fromApi(json);
      _navKey.currentState?.push(MaterialPageRoute(builder: (_) => MarketDetailScreen(market: market)));
    } catch (_) {
      // Unknown or unreachable market: stay on the normal home flow.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
      title: 'Callit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
