import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/stat_card.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  bool _includeDeleted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final search = _searchCtrl.text.trim();
      final q = search.isNotEmpty ? '&search=$search' : '';
      final res = await ApiClient.instance.get(
          '/api/superadmin/users?includeDeleted=$_includeDeleted$q');
      setState(() { _users = res['data']['items']; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _suspend(Map u, bool suspend) async {
    final note = await _noteDialog(
        suspend ? 'Suspend User' : 'Unsuspend User',
        suspend ? 'Reason for suspension?' : 'Note for unsuspension');
    if (note == null) return;
    try {
      await ApiClient.instance.post('/api/superadmin/users/${u['id']}/suspend',
          {'suspend': suspend, 'note': note});
      _load();
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  Future<void> _delete(Map u) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Delete User',
        message: 'Delete ${u['displayName']}? This cannot be undone.',
      ),
    );
    if (confirm != true) return;
    try {
      await ApiClient.instance.delete('/api/superadmin/users/${u['id']}');
      _load();
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  Future<String?> _noteDialog(String title, String hint) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.danger));
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
            const SectionHeader(title: 'Users'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Search by name or email...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _includeDeleted,
                      onChanged: (v) {
                        setState(() => _includeDeleted = v!);
                        _load();
                      },
                      activeColor: AppTheme.primary,
                    ),
                    const Text('Include Deleted',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Expanded(child: LoadingView())
            else if (_error != null)
              Expanded(child: ErrorView(message: _error!, onRetry: _load))
            else
              Expanded(
                child: Card(
                  child: _users.isEmpty
                      ? const Center(
                          child: Text('No users found',
                              style: TextStyle(color: AppTheme.textSecondary)))
                      : ListView.separated(
                          itemCount: _users.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) => _UserTile(
                            user: _users[i],
                            onSuspend: () => _suspend(_users[i], !_users[i]['isSuspended']),
                            onDelete: () => _delete(_users[i]),
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map user;
  final VoidCallback onSuspend;
  final VoidCallback onDelete;

  const _UserTile({required this.user, required this.onSuspend, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isSuspended = user['isSuspended'] as bool;
    final isDeleted = user['isDeleted'] as bool;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primary.withOpacity(0.2),
        child: Text(
          (user['displayName'] as String).substring(0, 1).toUpperCase(),
          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
        ),
      ),
      title: Row(
        children: [
          Text(user['displayName'],
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          if (isSuspended) const StatusBadge(label: 'Suspended', color: AppTheme.warning),
          if (isDeleted) const StatusBadge(label: 'Deleted', color: AppTheme.danger),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user['email'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          Text('Points: ${user['totalPoints']}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
      trailing: isDeleted
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  icon: Icon(
                    isSuspended ? Icons.lock_open : Icons.lock,
                    size: 14,
                    color: isSuspended ? AppTheme.accent : AppTheme.warning,
                  ),
                  label: Text(
                    isSuspended ? 'Unsuspend' : 'Suspend',
                    style: TextStyle(
                        color: isSuspended ? AppTheme.accent : AppTheme.warning,
                        fontSize: 12),
                  ),
                  onPressed: onSuspend,
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 14, color: AppTheme.danger),
                  label: const Text('Delete',
                      style: TextStyle(color: AppTheme.danger, fontSize: 12)),
                  onPressed: onDelete,
                ),
              ],
            ),
      isThreeLine: true,
    );
  }
}
