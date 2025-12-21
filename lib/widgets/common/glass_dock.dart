import 'package:flutter/material.dart';
import 'glassmorphic_card.dart';

class GlassDock extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onAddTap;

  const GlassDock({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = scheme.onSurface;
    final inactiveColor = scheme.onSurface.withValues(alpha: 0.55);
    final bg = theme.scaffoldBackgroundColor;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          GlassmorphicCard(
            borderRadius: BorderRadius.circular(30),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
            blur: 18,
            opacity: isDark ? 0.20 : 0.16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  onTap: () => onTap(0),
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                  isSelected: currentIndex == 1,
                  onTap: () => onTap(1),
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                const SizedBox(width: 54),
                _buildNavItem(
                  context,
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Accounts',
                  isSelected: currentIndex == 2,
                  onTap: () => onTap(2),
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isSelected: currentIndex == 3,
                  onTap: () => onTap(3),
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              ],
            ),
          ),
          Positioned(
            top: -18,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -12,
            child: _buildAddButton(context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? activeColor : inactiveColor,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onAddTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.add,
          color: theme.colorScheme.onPrimary,
          size: 28,
        ),
      ),
    );
  }
}
