import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/stat_card.dart';

class MerchantsScreen extends StatefulWidget {
  const MerchantsScreen({super.key});
  @override
  State<MerchantsScreen> createState() => _MerchantsScreenState();
}

class _MerchantsScreenState extends State<MerchantsScreen> {
  List<dynamic> _merchants = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String _status = '';

  final _statusOptions = ['', 'pending', 'approved', 'rejected', 'suspended'];

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
      final q = StringBuffer('/api/superadmin/merchants?');
      if (_searchCtrl.text.trim().isNotEmpty) q.write('search=${_searchCtrl.text.trim()}&');
      if (_status.isNotEmpty) q.write('status=$_status&');
      final res = await ApiClient.instance.get(q.toString());
      setState(() { _merchants = res['data']['items']; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _review(Map m, bool approve) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text(approve ? 'Approve Merchant' : 'Reject Merchant',
            style: const TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              approve
                  ? 'Approve ${m['businessName']}?'
                  : 'Reject ${m['businessName']}?',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(hintText: 'Note (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: approve ? AppTheme.accent : AppTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiClient.instance.post('/api/superadmin/merchants/${m['id']}/review',
          {'approve': approve, 'note': ctrl.text});
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger));
      }
    }
  }

  Future<void> _suspend(Map m) async {
    final isSuspended = m['isSuspended'] as bool;
    try {
      await ApiClient.instance.post('/api/superadmin/merchants/${m['id']}/suspend',
          {'suspend': !isSuspended, 'note': ''});
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger));
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return AppTheme.accent;
      case 'pending': return AppTheme.warning;
      case 'rejected': return AppTheme.danger;
      default: return AppTheme.textSecondary;
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
            const SectionHeader(title: 'Merchants'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Search merchants...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _status,
                  dropdownColor: AppTheme.card,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  hint: const Text('Status'),
                  items: _statusOptions
                      .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.isEmpty ? 'All Status' : s,
                              style: const TextStyle(color: AppTheme.textPrimary))))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _status = v!);
                    _load();
                  },
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
                  child: _merchants.isEmpty
                      ? const Center(
                          child: Text('No merchants found',
                              style: TextStyle(color: AppTheme.textSecondary)))
                      : ListView.separated(
                          itemCount: _merchants.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final m = _merchants[i] as Map;
                            final status = m['status'] as String;
                            final isSuspended = m['isSuspended'] as bool;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _statusColor(status).withOpacity(0.15),
                                child: Icon(Icons.store, color: _statusColor(status), size: 20),
                              ),
                              title: Row(
                                children: [
                                  Text(m['businessName'],
                                      style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  StatusBadge(label: status, color: _statusColor(status)),
                                  if (isSuspended) ...[
                                    const SizedBox(width: 6),
                                    const StatusBadge(
                                        label: 'Suspended', color: AppTheme.warning),
                                  ],
                                ],
                              ),
                              subtitle: Text(m['phone'],
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary, fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (status == 'pending') ...[
                                    TextButton(
                                      onPressed: () => _review(m, true),
                                      child: const Text('Approve',
                                          style: TextStyle(color: AppTheme.accent)),
                                    ),
                                    TextButton(
                                      onPressed: () => _review(m, false),
                                      child: const Text('Reject',
                                          style: TextStyle(color: AppTheme.danger)),
                                    ),
                                  ] else
                                    TextButton.icon(
                                      icon: Icon(
                                        isSuspended ? Icons.lock_open : Icons.lock,
                                        size: 14,
                                        color: isSuspended
                                            ? AppTheme.accent
                                            : AppTheme.warning,
                                      ),
                                      label: Text(
                                        isSuspended ? 'Unsuspend' : 'Suspend',
                                        style: TextStyle(
                                            color: isSuspended
                                                ? AppTheme.accent
                                                : AppTheme.warning,
                                            fontSize: 12),
                                      ),
                                      onPressed: () => _suspend(m),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
