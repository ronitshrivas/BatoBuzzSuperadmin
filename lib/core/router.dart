import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'auth/auth_provider.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/users/screens/users_screen.dart';
import '../features/merchants/screens/merchants_screen.dart';
import '../features/moderation/screens/moderation_screen.dart';
import '../features/points/screens/points_screen.dart';
import '../features/broadcast/screens/broadcast_screen.dart';
import '../features/audit/screens/audit_screen.dart';
import '../shared/widgets/login_screen.dart';
import '../shared/widgets/shell_screen.dart';

GoRouter buildRouter(AuthProvider auth) => GoRouter(
      refreshListenable: auth,
      redirect: (context, state) {
        if (auth.loading) return null;
        final loggedIn = auth.loggedIn;
        final onLogin = state.matchedLocation == '/login';
        if (!loggedIn && !onLogin) return '/login';
        if (loggedIn && onLogin) return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        ShellRoute(
          builder: (context, state, child) => ShellScreen(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
            GoRoute(path: '/users', builder: (_, __) => const UsersScreen()),
            GoRoute(path: '/merchants', builder: (_, __) => const MerchantsScreen()),
            GoRoute(path: '/moderation', builder: (_, __) => const ModerationScreen()),
            GoRoute(path: '/points', builder: (_, __) => const PointsScreen()),
            GoRoute(path: '/broadcast', builder: (_, __) => const BroadcastScreen()),
            GoRoute(path: '/audit', builder: (_, __) => const AuditScreen()),
          ],
        ),
      ],
    );
