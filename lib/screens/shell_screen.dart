import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_profile_provider.dart';

class ShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final navbarStyle = profile?.navbarStyle ?? 'expand'; // Default to Option A ('expand')

    final items = [
      _NavDestination(
        index: 0,
        outlineIcon: Icons.home_outlined,
        filledIcon: Icons.home,
        label: 'Dashboard',
      ),
      _NavDestination(
        index: 1,
        outlineIcon: Icons.account_balance_wallet_outlined,
        filledIcon: Icons.account_balance_wallet,
        label: 'Ledger',
      ),
      _NavDestination(
        index: 2,
        outlineIcon: Icons.bar_chart_outlined,
        filledIcon: Icons.bar_chart,
        label: 'Projection',
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Screen content
          navigationShell,
          // Floating Bottom Navigation Bar
          Positioned(
            bottom: 20,
            left: 24,
            right: 24,
            child: SafeArea(
              top: false,
              bottom: true,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111215).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: const Color(0xFF1F2128),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: items.map((item) {
                          final isSelected = navigationShell.currentIndex == item.index;

                          if (navbarStyle == 'icons_only') {
                            return _buildIconsOnlyItem(context, item, isSelected);
                          } else {
                            return _buildExpandableItem(context, item, isSelected);
                          }
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableItem(BuildContext context, _NavDestination item, bool isSelected) {
    return GestureDetector(
      onTap: () => _onDestinationSelected(item.index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF818CF8).withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.filledIcon : item.outlineIcon,
              color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF8E8E93),
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF818CF8),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconsOnlyItem(BuildContext context, _NavDestination item, bool isSelected) {
    return GestureDetector(
      onTap: () => _onDestinationSelected(item.index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.filledIcon : item.outlineIcon,
              color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF8E8E93),
              size: 22,
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF818CF8) : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDestinationSelected(int index) {
    HapticFeedback.lightImpact();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _NavDestination {
  final int index;
  final IconData outlineIcon;
  final IconData filledIcon;
  final String label;

  const _NavDestination({
    required this.index,
    required this.outlineIcon,
    required this.filledIcon,
    required this.label,
  });
}
