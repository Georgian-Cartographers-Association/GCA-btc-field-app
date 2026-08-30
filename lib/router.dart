import 'package:go_router/go_router.dart';
import 'models/btk_record.dart';
import 'features/auth/ui/auth_screen.dart';
import 'features/expedition/ui/expedition_screen.dart';
import 'features/gps/ui/gps_track_history_screen.dart';
import 'features/layers/ui/layers_screen.dart';
import 'features/map/ui/map_screen.dart';
import 'features/pdf/ui/pdf_viewer_screen.dart';
import 'features/records/ui/records_screen.dart';
import 'features/settings/ui/settings_screen.dart';
import 'features/form/ui/btk_form_screen.dart';
import 'features/stats/ui/stats_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const MapScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, _) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (_, _) => const AuthScreen(),
    ),
    GoRoute(
      path: '/expedition',
      builder: (_, _) => const ExpeditionScreen(),
    ),
    GoRoute(
      path: '/records',
      builder: (_, _) => const RecordsScreen(),
    ),
    GoRoute(
      path: '/form',
      builder: (_, state) => BtkFormScreen(record: state.extra as BtkRecord),
    ),
    GoRoute(
      path: '/gps',
      builder: (_, _) => const GpsTrackHistoryScreen(),
    ),
    GoRoute(
      path: '/layers',
      builder: (_, _) => const LayersScreen(),
    ),
    GoRoute(
      path: '/pdf',
      builder: (_, _) => const PdfViewerScreen(),
    ),
    GoRoute(
      path: '/stats',
      builder: (_, _) => const StatsScreen(),
    ),
  ],
);
