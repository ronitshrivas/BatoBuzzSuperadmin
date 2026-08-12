import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/stat_card.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});
  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  final _userIdCtrl = TextEditingController();
  final _deltaCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  Map<String, dynamic>? _pointsData;
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _deltaCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final id = _userIdCtrl.text.trim();
    if (id.isEmpty) return;
    setState(() { _loading = true; _error = null; _success = null; _pointsData = null; });
    try {
      final res = await ApiClient.instance.get('/api/superadmin/users/$id/points');
      setState(() { _pointsData = res['data']; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _adjust() async {
    final id = _userIdCtrl.text.trim();
    final delta = int.tryParse(_deltaCtrl.text.trim());
    final reason = _reasonCtrl.text.trim();
    if (id.isEmpty || delta == null || reason.isEmpty) {
      setState(() => _error = 'Please fill all fields with valid values.');
      return;
    }
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      final res = await ApiClient.instance.post(
          '/api/superadmin/users/$id/points/adjust', {'delta': delta, 'reason': reason});
      setState(() {
        _pointsData = res['data'];
        _success = 'Points adjusted successfully!';
        _deltaCtrl.clear();
        _reasonCtrl.clear();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
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
            const SectionHeader(title: 'Points Management'),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Look Up User Points',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _userIdCtrl,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'User ID (UUID)',
                              prefixIcon: Icon(Icons.person_search),
                            ),
                            onSubmitted: (_) => _lookup(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _loading ? null : _lookup,
                          child: const Text('Look Up'),
                        ),
                      ],
                    ),
                    if (_pointsData != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars, color: Colors.amber, size: 32),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Points',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary, fontSize: 12)),
                                Text(
                                  '${_pointsData!['totalPoints']}',
                                  style: const TextStyle(
                                      color: Colors.amber,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Adjust Points',
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _deltaCtrl,
                              style: const TextStyle(color: AppTheme.textPrimary),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Delta (e.g. +50 or -20)',
                                prefixIcon: Icon(Icons.add_circle_outline),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _reasonCtrl,
                              style: const TextStyle(color: AppTheme.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Reason',
                                prefixIcon: Icon(Icons.edit_note),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _loading ? null : _adjust,
                            child: const Text('Adjust'),
                          ),
                        ],
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error!,
                            style: const TextStyle(color: AppTheme.danger)),
                      ),
                    ],
                    if (_success != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_success!,
                            style: const TextStyle(color: AppTheme.accent)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
