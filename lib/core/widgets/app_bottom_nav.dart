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
          border: Border(top: BorderSide(color: AppColors.ink, width: 1.3)),
        ),
        child: Row(
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final selected = index == currentIndex;

            if (item.icon == null) {
              // Center "Create" button — a boxy, bordered highlight square.
              return Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () => onTap(index),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.highlight,
                        border: Border.all(color: AppColors.ink, width: 1.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.add_rounded, color: AppColors.ink, size: 24),
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
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: selected ? Border.all(color: AppColors.ink, width: 1.3) : null,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(item.icon, color: color, size: 20),
                    ),
                    const SizedBox(height: 2),
                    Text(item.label.toUpperCase(), style: AppTextStyles.label(10, weight: FontWeight.w600, color: color)),
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
