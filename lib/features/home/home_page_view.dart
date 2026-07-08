import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/analytics_service.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/launch_screen_provider.dart';
import '../calendar/calendar_screen.dart';
import 'home_screen.dart';

class HomePageView extends ConsumerStatefulWidget {
  const HomePageView({super.key});

  @override
  ConsumerState<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends ConsumerState<HomePageView> {
  late final PageController _pageController;
  final _searchFocus = FocusNode();
  late int _page;
  bool _showSwipeHint = false;

  static const _hintKey = 'home_swipe_hint_dismissed';

  @override
  void initState() {
    super.initState();
    final launchScreen = ref.read(resolvedLaunchScreenProvider);
    _page = launchScreen == LaunchScreen.calendar ? 1 : 0;
    _pageController = PageController(initialPage: _page);
    _searchFocus.addListener(() => setState(() {}));
    _loadHintState();
    if (launchScreen == LaunchScreen.calculatorHub) {
      _openCalculatorHubOnLaunch();
    }
  }

  /// Pushes the existing Calculator Hub route on top of Home after the first
  /// frame — a normal launch only, never overriding a deep link or other
  /// explicit navigation that may have already moved away from `/`.
  void _openCalculatorHubOnLaunch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (GoRouterState.of(context).uri.toString() != '/') return;
      context.push('/calculators', extra: true);
    });
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
