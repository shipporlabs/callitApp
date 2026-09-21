import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.search_rounded, label: 'Markets'),
    (icon: null, label: 'Create'), // center action, styled differently
    (icon: Icons.account_balance_wallet_rounded, label: 'Wallet'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 74,
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.mist)),
        ),
        child: Row(
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final selected = index == currentIndex;

            if (item.icon == null) {
              // Center "Create" button — a raised highlight pill.
              return Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () => onTap(index),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(color: AppColors.highlight, shape: BoxShape.circle),
                      child: const Icon(Icons.add_rounded, color: AppColors.ink, size: 26),
                    ),
                  ),
                ),
              );
            }

            final color = selected ? AppColors.ink : AppColors.slate;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, color: color, size: 24),
                    const SizedBox(height: 4),
                    Text(item.label, style: AppTextStyles.body(11, weight: FontWeight.w600, color: color)),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
