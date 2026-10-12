import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_key_store.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _loading = true;
  bool _hasSavedKey = false;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await ApiKeyStore.getIpoGuruKey();
    if (!mounted) return;
    setState(() {
      _controller.text = key ?? '';
      _hasSavedKey = key != null && key.isNotEmpty;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a key first, or use Remove to clear it.')),
      );
      return;
    }
    await ApiKeyStore.setIpoGuruKey(value);
    if (!mounted) return;
    setState(() => _hasSavedKey = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key saved')),
    );
  }

  Future<void> _remove() async {
    await ApiKeyStore.clearIpoGuruKey();
    if (!mounted) return;
    setState(() {
      _controller.clear();
      _hasSavedKey = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key removed')),
    );
  }

  Future<void> _openRequestKeyPage() async {
    final uri = Uri.parse('https://www.ipoguru.in/ipo-gmp-details-developer-api');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the browser')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IPO Data Sync')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cloud_sync_outlined, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('IPO Guru API', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add your free IPO Guru API key to pull the current IPO calendar '
                          '(company name, dates, price band, and status) with one tap instead of typing it in manually. '
                          'The free plan allows 10 syncs per day.',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _openRequestKeyPage,
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text("Don't have a key? Request one (free)"),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        child: const Text('SAVE'),
                      ),
                    ),
                    if (_hasSavedKey) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _remove,
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('REMOVE'),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('What this does NOT do', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      SizedBox(height: 6),
                      Text(
                        '• Never sends your PAN, Demat, or application data anywhere\n'
                        '• Never checks allotment status automatically\n'
                        '• Only fetches public market data when you tap "Sync"\n'
                        '• Your key is stored only on this device',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'IPO data via IPO Guru (ipoguru.in)',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
    );
  }
}
