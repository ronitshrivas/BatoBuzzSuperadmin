import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/stat_card.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});
  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  List<dynamic> _entries = [];
  bool _loading = true;
  String? _error;
  final _fmt = DateFormat('MMM d, yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient.instance.get('/api/superadmin/audit?pageSize=100');
      setState(() { _entries = res['data']['items']; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Color _actionColor(String action) {
    if (action.toLowerCase().contains('delete')) return AppTheme.danger;
    if (action.toLowerCase().contains('suspend')) return AppTheme.warning;
    if (action.toLowerCase().contains('approve')) return AppTheme.accent;
    if (action.toLowerCase().contains('broadcast')) return AppTheme.primary;
    return AppTheme.textSecondary;
  }

  IconData _actionIcon(String action) {
    if (action.toLowerCase().contains('delete')) return Icons.delete;
    if (action.toLowerCase().contains('suspend')) return Icons.lock;
    if (action.toLowerCase().contains('approve')) return Icons.check_circle;
    if (action.toLowerCase().contains('broadcast')) return Icons.campaign;
    if (action.toLowerCase().contains('adjust')) return Icons.stars;
    return Icons.history;
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
            SectionHeader(
              title: 'Audit Log',
              action: IconButton(
                icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
                onPressed: _load,
              ),
            ),
            const SizedBox(height: 8),
            const Text('All admin actions are recorded here.',
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            if (_loading)
              const Expanded(child: LoadingView())
            else if (_error != null)
              Expanded(child: ErrorView(message: _error!, onRetry: _load))
            else
              Expanded(
                child: Card(
                  child: _entries.isEmpty
                      ? const Center(
                          child: Text('No audit entries found.',
                              style: TextStyle(color: AppTheme.textSecondary)))
                      : ListView.separated(
                          itemCount: _entries.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final e = _entries[i] as Map;
                            final action = e['action'] as String;
                            final color = _actionColor(action);
                            final createdAt = DateTime.tryParse(e['createdAt'] ?? '');
                            return ListTile(
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(_actionIcon(action), color: color, size: 18),
                              ),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(action,
                                        style: TextStyle(
                                            color: color,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(e['targetType'] ?? '',
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary, fontSize: 12)),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'By: ${e['actorName']}',
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary, fontSize: 12),
                                  ),
                                  if (e['detail'] != null)
                                    Text(e['detail'],
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary, fontSize: 11)),
                                ],
                              ),
                              trailing: createdAt != null
                                  ? Text(_fmt.format(createdAt.toLocal()),
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary, fontSize: 11))
                                  : null,
                              isThreeLine: true,
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
