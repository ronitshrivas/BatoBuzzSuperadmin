import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/stat_card.dart';

class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});
  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _posts = [];
  List<dynamic> _reports = [];
  bool _loadingPosts = true;
  bool _loadingReports = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadPosts();
    _loadReports();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => _loadingPosts = true);
    try {
      final res = await ApiClient.instance.get(
        '/api/superadmin/posts?includeDeleted=false',
      );
      setState(() {
        _posts = res['data']['items'];
        _loadingPosts = false;
      });
    } catch (e) {
      setState(() => _loadingPosts = false);
    }
  }

  Future<void> _loadReports() async {
    setState(() => _loadingReports = true);
    try {
      final res = await ApiClient.instance.get('/api/superadmin/reports');
      setState(() {
        _reports = res['data']['items'];
        _loadingReports = false;
      });
    } catch (e) {
      setState(() => _loadingReports = false);
    }
  }

  Future<void> _deletePost(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmDialog(
        title: 'Remove Post',
        message: 'Remove this post from the platform?',
      ),
    );
    if (confirm != true) return;
    try {
      await ApiClient.instance.delete(
        '/api/superadmin/posts/$id?reason=Admin+removed',
      );
      _loadPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _restorePost(String id) async {
    try {
      await ApiClient.instance.post('/api/superadmin/posts/$id/restore', {});
      _loadPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _resolveReport(String id) async {
    try {
      await ApiClient.instance.post('/api/superadmin/reports/$id/resolve', {});
      _loadReports();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Moderation'),
            const SizedBox(height: 20),
            TabBar(
              controller: _tab,
              isScrollable: true,
              indicatorColor: AppTheme.primary,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              tabs: [
                Tab(text: 'Posts (${_posts.length})'),
                Tab(text: 'Reports (${_reports.length})'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  // Posts
                  _loadingPosts
                      ? const LoadingView()
                      : Card(
                          child: ListView.separated(
                            itemCount: _posts.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final p = _posts[i] as Map;
                              final isDeleted = p['isDeleted'] as bool;
                              return ListTile(
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    p['postType'] == 'reel'
                                        ? Icons.video_library
                                        : Icons.article,
                                    color: AppTheme.primary,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  () {
                                    final body = p['body']?.toString() ?? '';
                                    return body.length > 60
                                        ? '${body.substring(0, 60)}...'
                                        : body;
                                  }(),
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    StatusBadge(
                                      label: p['postType'],
                                      color: AppTheme.primary,
                                    ),
                                    if (isDeleted) ...[
                                      const SizedBox(width: 6),
                                      const StatusBadge(
                                        label: 'Deleted',
                                        color: AppTheme.danger,
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: isDeleted
                                    ? TextButton(
                                        onPressed: () => _restorePost(p['id']),
                                        child: const Text(
                                          'Restore',
                                          style: TextStyle(
                                            color: AppTheme.accent,
                                          ),
                                        ),
                                      )
                                    : TextButton.icon(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 14,
                                          color: AppTheme.danger,
                                        ),
                                        label: const Text(
                                          'Remove',
                                          style: TextStyle(
                                            color: AppTheme.danger,
                                            fontSize: 12,
                                          ),
                                        ),
                                        onPressed: () => _deletePost(p['id']),
                                      ),
                              );
                            },
                          ),
                        ),
                  // Reports
                  _loadingReports
                      ? const LoadingView()
                      : Card(
                          child: _reports.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: AppTheme.accent,
                                        size: 48,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'No open reports!',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: _reports.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (_, i) {
                                    final r = _reports[i] as Map;
                                    return ListTile(
                                      leading: const Icon(
                                        Icons.flag,
                                        color: AppTheme.danger,
                                      ),
                                      title: Text(
                                        r['reason'],
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Post: ${r['postId']}',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                      trailing: TextButton(
                                        onPressed: () =>
                                            _resolveReport(r['id']),
                                        child: const Text(
                                          'Resolve',
                                          style: TextStyle(
                                            color: AppTheme.accent,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
