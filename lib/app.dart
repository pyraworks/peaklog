import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'l10n/app_localizations.dart';
import 'core/models/note.dart';
import 'core/theme/app_theme.dart';
import 'features/exercise_detail/exercise_detail_screen.dart';
import 'features/export/export_screen.dart';
import 'features/share/share_screen.dart';
import 'features/home/add_exercise_sheet.dart';
import 'features/home/home_page_view.dart';
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
      builder: (context, state) => const HomePageView(),
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
      builder: (context, state) => CalculatorHubScreen(
        isLaunchScreen: state.extra == true,
      ),
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
      path: '/share',
      builder: (context, state) =>
          ShareScreen(backLabel: AppLocalizations.of(context)!.homeLabel),
    ),
    GoRoute(
      path: '/share/:recordId',
      builder: (context, state) => const ShareScreen(),
    ),
    // Reuses the exact same visual share/customization screen and final
    // SharePlus pipeline as workout Record/Activity sharing above — see
    // ExportScreen's Note mode. The Note itself travels as `extra` (the
    // established pattern for non-path-parameter route data in this app;
    // see /calculators/1rm-table).
    GoRoute(
      path: '/share/note',
      builder: (context, state) => ExportScreen(note: state.extra as Note),
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
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
      ],
    );
  }
}

class _Error404Screen extends StatelessWidget {
  const _Error404Screen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('404', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(l10n.pageNotFound),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: Text(l10n.goHome),
            ),
          ],
        ),
      ),
    );
  }
}
