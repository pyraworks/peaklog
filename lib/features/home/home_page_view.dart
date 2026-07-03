import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/analytics_service.dart';
import '../../providers/analytics_provider.dart';
import '../calendar/calendar_screen.dart';
import 'home_screen.dart';

class HomePageView extends ConsumerStatefulWidget {
  const HomePageView({super.key});

  @override
  ConsumerState<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends ConsumerState<HomePageView> {
  final _pageController = PageController();
  final _searchFocus = FocusNode();
  int _page = 0;
  bool _showSwipeHint = false;

  static const _hintKey = 'home_swipe_hint_dismissed';

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() => setState(() {}));
    _loadHintState();
  }

  Future<void> _loadHintState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _showSwipeHint = !(prefs.getBool(_hintKey) ?? false);
    });
  }

  Future<void> _dismissHint() async {
    if (!_showSwipeHint) return;
    setState(() => _showSwipeHint = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hintKey, true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchFocus.dispose();
    super.dispose();
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
          if (index == 1) {
            _dismissHint();
            unawaited(ref.read(analyticsProvider).logCalendarOpened(
              entry: CalendarEntryMethod.swipe,
            ));
          }
        },
        children: [
          HomeScreen(searchFocus: _searchFocus, showSwipeHint: _showSwipeHint),
          const CalendarScreen(),
        ],
      ),
    );
  }
}
