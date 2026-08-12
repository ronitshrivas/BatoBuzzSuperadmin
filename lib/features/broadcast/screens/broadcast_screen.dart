import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/stat_card.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});
  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _audience = 'all';
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) {
      setState(() => _error = 'Title and body are required.');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Send Broadcast',
        message:
            'Send "${_titleCtrl.text}" to all $_audience? This will send a push notification.',
        confirmLabel: 'Send',
        confirmColor: AppTheme.primary,
      ),
    );
    if (confirm != true) return;
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      final res = await ApiClient.instance.post('/api/superadmin/broadcast', {
        'audience': _audience,
        'title': _titleCtrl.text,
        'body': _bodyCtrl.text,
      });
      final recipients = res['data']['recipients'];
      setState(() {
        _success = 'Broadcast sent to $recipients recipients!';
        _titleCtrl.clear();
        _bodyCtrl.clear();
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
            const SectionHeader(title: 'Broadcast Notification'),
            const SizedBox(height: 8),
            const Text('Send push notifications to users or merchants.',
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Audience',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _AudienceChip(
                            label: 'All', value: 'all', selected: _audience == 'all',
                            onTap: () => setState(() => _audience = 'all')),
                        const SizedBox(width: 8),
                        _AudienceChip(
                            label: 'Users Only', value: 'users', selected: _audience == 'users',
                            onTap: () => setState(() => _audience = 'users')),
                        const SizedBox(width: 8),
                        _AudienceChip(
                            label: 'Merchants Only', value: 'merchants',
                            selected: _audience == 'merchants',
                            onTap: () => setState(() => _audience = 'merchants')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _titleCtrl,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Notification Title',
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bodyCtrl,
                      maxLines: 4,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Message Body',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 60),
                          child: Icon(Icons.message),
                        ),
                      ),
                    ),
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
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppTheme.accent, size: 16),
                            const SizedBox(width: 8),
                            Text(_success!,
                                style: const TextStyle(color: AppTheme.accent)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _send,
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send),
                        label: Text(_loading ? 'Sending...' : 'Send Broadcast'),
                      ),
                    ),
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

class _AudienceChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _AudienceChip(
      {required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? AppTheme.primary : Colors.white12),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13)),
      ),
    );
  }
}
