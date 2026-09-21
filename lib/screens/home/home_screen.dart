import 'package:flutter/material.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../create/paste_screen.dart';
import '../profile/profile_screen.dart';
import '../wallet/wallet_screen.dart';
import 'markets_tab.dart';

/// The shell that owns bottom-nav state. Each tab is a plain widget, so
/// screens stay simple and testable on their own.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  void _onNavTap(int index) {
    if (index == 2) {
      // Create tab opens as a full-screen flow rather than replacing the body.
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PasteScreen()));
      return;
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const MarketsTab(),
      const MarketsTab(searchMode: true),
      const SizedBox.shrink(), // placeholder for index 2 (Create), never shown
      const WalletScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: AppBottomNav(currentIndex: _index, onTap: _onNavTap),
    );
  }
}
