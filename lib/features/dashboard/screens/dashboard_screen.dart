import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient.instance.get('/api/superadmin/dashboard');
      setState(() { _stats = res['data']; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final s = _stats!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Overview of your platform',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 28),
          _grid([
            StatCard(
              label: 'Total Users',
              value: '${s['totalUsers']}',
              icon: Icons.people,
              color: AppTheme.primary,
              subtitle: '${s['suspendedUsers']} suspended',
            ),
            StatCard(
              label: 'Total Merchants',
              value: '${s['totalMerchants']}',
              icon: Icons.store,
              color: AppTheme.accent,
              subtitle: '${s['pendingMerchants']} pending',
            ),
            StatCard(
              label: 'Approved Merchants',
              value: '${s['approvedMerchants']}',
              icon: Icons.verified,
              color: Colors.green,
            ),
            StatCard(
              label: 'Open Reports',
              value: '${s['openReports']}',
              icon: Icons.flag,
              color: AppTheme.danger,
            ),
            StatCard(
              label: 'Total Posts',
              value: '${s['totalPosts']}',
              icon: Icons.article,
              color: Colors.orange,
            ),
            StatCard(
              label: 'Total Reels',
              value: '${s['totalReels']}',
              icon: Icons.video_library,
              color: Colors.purple,
            ),
            StatCard(
              label: 'Total Jobs',
              value: '${s['totalJobs']}',
              icon: Icons.work,
              color: Colors.blue,
            ),
            StatCard(
              label: 'Award Participants',
              value: '${s['activeAwardParticipants']}',
              icon: Icons.emoji_events,
              color: Colors.amber,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _grid(List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 900
          ? 4
          : constraints.maxWidth > 600
              ? 2
              : 1;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.4,
        children: children,
      );
    });
  }
}
