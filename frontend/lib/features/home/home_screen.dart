import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'tabs/home_tab.dart';
import 'tabs/career_tab.dart';
import 'tabs/learn_tab.dart';
import 'tabs/community_tab.dart';
import 'tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.work_rounded, label: 'Career'),
    _NavItem(icon: Icons.menu_book_rounded, label: 'Learn'),
    _NavItem(icon: Icons.people_rounded, label: 'Community'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  void _switchTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeTab(onNavigateToTab: _switchTab),
          const CareerTab(),
          const LearnTab(),
          const CommunityTab(),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _selectedIndex == index;

              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: isSelected ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          item.icon,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMuted,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMuted,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
