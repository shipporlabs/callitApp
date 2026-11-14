import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'app_icon.dart';

/// Floating pill navigation: soft border, no shadow. The selected tab gets an
/// ink disc, Create is the one yellow action.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = <({List<List<dynamic>>? icon, String label})>[
    (icon: Ic.home, label: 'Home'),
    (icon: Ic.search, label: 'Markets'),
    (icon: null, label: 'Create'),
    (icon: Ic.user, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.mist, width: 1.2),
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = index == currentIndex;
              return Expanded(
                child: Semantics(
                  button: true,
                  label: item.label,
                  selected: selected,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(index),
                    child: Center(
                      child: item.icon == null
                          ? Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(color: AppColors.highlight, shape: BoxShape.circle),
                              child: const Center(child: AppIcon(Ic.add, size: 24, strokeWidth: 2)),
                            )
                          : AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(color: selected ? AppColors.ink : Colors.transparent, shape: BoxShape.circle),
                              child: Center(child: AppIcon(item.icon!, size: 22, color: selected ? AppColors.paper : AppColors.slate)),
                            ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
