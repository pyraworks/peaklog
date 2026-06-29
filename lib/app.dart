import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/exercise_detail/exercise_detail_screen.dart';
import 'features/share/quick_share_placeholder_screen.dart';
import 'features/home/add_exercise_sheet.dart';
import 'features/home/home_share_page_view.dart';
import 'features/one_rm_table/one_rm_table_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/record_input/edit_record_screen.dart';
import 'features/categories/category_management_screen.dart';
import 'features/record_input/record_detail_screen.dart';
import 'features/calculators/calculator_hub_screen.dart';
import 'features/calculators/one_rm_calculator_screen.dart';
import 'features/calculators/pace_calculator_screen.dart';
import 'features/calculators/plate_calculator_screen.dart';
import 'features/settings/settings_screen.dart';

final _router = GoRouter(
  errorBuilder: (context, state) => const _Error404Screen(),
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeSharePageView(),
    ),
    GoRoute(
      path: '/exercise/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ExerciseDetailScreen(exerciseId: id);
      },
    ),
    GoRoute(
      path: '/exercise/:id/1rm-table',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return OneRMTableScreen(exerciseId: id);
      },
    ),
    GoRoute(
      path: '/exercise/:id/record/:rid',
      builder: (context, state) {
        final exerciseId = state.pathParameters['id']!;
        final recordId = state.pathParameters['rid']!;
        return RecordDetailScreen(
          exerciseId: exerciseId,
          recordId: recordId,
        );
      },
    ),
    GoRoute(
      path: '/exercise/:id/record/:rid/edit',
      builder: (context, state) {
        final exerciseId = state.pathParameters['id']!;
        final recordId = state.pathParameters['rid']!;
        return EditRecordScreen(
          exerciseId: exerciseId,
          recordId: recordId,
        );
      },
    ),
    GoRoute(
      path: '/add-exercise',
      builder: (context, state) => const AddExerciseSheet(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/calculators',
      builder: (context, state) => const CalculatorHubScreen(),
    ),
    GoRoute(
      path: '/calculators/1rm',
      builder: (context, state) => const OneRmCalculatorScreen(),
    ),
    GoRoute(
      path: '/calculators/1rm-table',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return OneRMTableScreen(
          directWeightKg: (extra?['weight'] as num?)?.toDouble(),
          directWeightUnit: extra?['unit'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/calculators/pace',
      builder: (context, state) => const PaceCalculatorScreen(),
    ),
    GoRoute(
      path: '/calculators/plate',
      builder: (context, state) => const PlateCalculatorScreen(),
    ),
    GoRoute(
      path: '/quick-share',
      builder: (context, state) =>
          const QuickSharePlaceholderScreen(backLabel: 'Home'),
    ),
    GoRoute(
      path: '/share/:recordId',
      builder: (context, state) => const QuickSharePlaceholderScreen(),
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoryManagementScreen(),
    ),
  ],
);

class PeakLogApp extends StatelessWidget {
  const PeakLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PeakLog',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
      ],
    );
  }
}

class _Error404Screen extends StatelessWidget {
  const _Error404Screen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('404', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Page not found'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
