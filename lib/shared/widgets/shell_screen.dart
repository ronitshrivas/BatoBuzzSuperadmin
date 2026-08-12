import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final location = GoRouterState.of(context).matchedLocation;
    final isMobile = MediaQuery.of(context).size.width < 800;

    final navItems = [
      _NavItem('/', Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
      _NavItem('/users', Icons.people_outline, Icons.people, 'Users'),
      _NavItem('/merchants', Icons.store_outlined, Icons.store, 'Merchants'),
      _NavItem('/moderation', Icons.shield_outlined, Icons.shield, 'Moderation'),
      _NavItem('/points', Icons.stars_outlined, Icons.stars, 'Points'),
      if (auth.isSuperAdmin) ...[
        _NavItem('/broadcast', Icons.campaign_outlined, Icons.campaign, 'Broadcast'),
        _NavItem('/audit', Icons.history_outlined, Icons.history, 'Audit Log'),
      ],
    ];

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.bolt, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('BatoBuzz Admin'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => auth.logout(),
            ),
          ],
        ),
        drawer: _Sidebar(navItems: navItems, location: location, auth: auth),
        body: child,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(navItems: navItems, location: location, auth: auth),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.path, this.icon, this.activeIcon, this.label);
}

class _Sidebar extends StatelessWidget {
  final List<_NavItem> navItems;
  final String location;
  final AuthProvider auth;

  const _Sidebar({
    required this.navItems,
    required this.location,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppTheme.card,
      child: Column(
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bolt, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BatoBuzz',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text('Admin Panel',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: auth.isSuperAdmin
                    ? AppTheme.primary.withOpacity(0.15)
                    : AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    auth.isSuperAdmin ? Icons.security : Icons.admin_panel_settings,
                    size: 14,
                    color: auth.isSuperAdmin ? AppTheme.primary : AppTheme.accent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      auth.isSuperAdmin ? 'Super Admin' : 'Admin',
                      style: TextStyle(
                        color: auth.isSuperAdmin ? AppTheme.primary : AppTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('MENU',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: navItems.map((item) {
                final active = location == item.path;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: ListTile(
                    leading: Icon(
                      active ? item.activeIcon : item.icon,
                      color: active ? AppTheme.primary : AppTheme.textSecondary,
                      size: 20,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: active ? AppTheme.primary : AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    tileColor: active ? AppTheme.primary.withOpacity(0.1) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onTap: () {
                      if (Scaffold.of(context).hasDrawer) {
                        Navigator.pop(context);
                      }
                      context.go(item.path);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primary.withOpacity(0.2),
                child: Text(
                  auth.displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              title: Text(auth.displayName,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
              trailing: IconButton(
                icon: const Icon(Icons.logout, size: 18),
                onPressed: () => auth.logout(),
                tooltip: 'Logout',
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
