import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/design/app_colors.dart';
import '../share/quick_share_screen.dart';
import 'home_screen.dart';

class HomeSharePageView extends StatefulWidget {
  const HomeSharePageView({super.key});

  @override
  State<HomeSharePageView> createState() => _HomeSharePageViewState();
}

class _HomeSharePageViewState extends State<HomeSharePageView> {
  final _pageController = PageController();
  final _searchFocus = FocusNode();
  int _page = 0;
  bool _showHint = false;

  static const _hintKey = 'share_swipe_hint_seen';

  @override
  void initState() {
    super.initState();
    _loadHint();
    _searchFocus.addListener(() => setState(() {}));
  }

  Future<void> _loadHint() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_hintKey) ?? false;
    if (!seen && mounted) setState(() => _showHint = true);
  }

  Future<void> _dismissHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hintKey, true);
    if (mounted) setState(() => _showHint = false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Widget _buildSwipeHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.actionDark.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '← Swipe for Share',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          letterSpacing: -0.2,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: PageView(
        controller: _pageController,
        physics: _searchFocus.hasFocus
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(parent: ClampingScrollPhysics()),
        onPageChanged: (index) {
          setState(() => _page = index);
          if (index == 1 && _showHint) _dismissHint();
        },
        children: [
          HomeScreen(searchFocus: _searchFocus, swipeHint: _showHint ? _buildSwipeHint() : null),
          const QuickShareScreen(embedded: true),
        ],
      ),
    );
  }
}
