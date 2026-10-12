import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ipo_provider.dart';
import '../../utils/ipo_import_parser.dart';
import '../../utils/date_utils.dart';

class ImportIposScreen extends StatefulWidget {
  const ImportIposScreen({super.key});

  @override
  State<ImportIposScreen> createState() => _ImportIposScreenState();
}

class _ImportIposScreenState extends State<ImportIposScreen> {
  final _controller = TextEditingController();
  List<ParsedIpoRow>? _preview;
  bool _importing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _insertSample() {
    setState(() {
      _controller.text = IpoImportParser.sampleTemplate;
      _preview = null;
    });
  }

  void _validate() {
    final text = _controller.text;
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste some IPO rows first')),
      );
      return;
    }
    setState(() {
      _preview = IpoImportParser.parse(text);
    });
  }

  Future<void> _importValidRows() async {
    final preview = _preview;
    if (preview == null) return;
    final validIpos = preview.where((r) => r.isValid).map((r) => r.ipo!).toList();
    if (validIpos.isEmpty) return;

    setState(() => _importing = true);
    final provider = Provider.of<IpoProvider>(context, listen: false);
    final inserted = await provider.addIposBulk(validIpos);
    setState(() => _importing = false);

    if (!mounted) return;
    final skipped = preview.length - validIpos.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          skipped > 0
              ? 'Imported $inserted IPOs. $skipped row(s) skipped (see errors above).'
              : 'Imported $inserted IPOs.',
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final validCount = preview?.where((r) => r.isValid).length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import IPOs'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.25),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('How this works', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        const Text(
                          'Paste rows copied from a spreadsheet or table, one IPO per line, '
                          'separated by commas or tabs:\n\n'
                          'Company Name, Open Date, Close Date, Type, Price Band, Allotment Date, Listing Date\n\n'
                          'Only the first 3 columns are required. Dates can be YYYY-MM-DD, DD/MM/YYYY, '
                          'or DD MMM YYYY (e.g. 12 Sep 2026). A header row is detected and skipped automatically.',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _insertSample,
                            icon: const Icon(Icons.auto_fix_high, size: 16),
                            label: const Text('Insert sample format'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Company Name, Open Date, Close Date, Type, Price Band, ...',
                    alignLabelWithHint: true,
                  ),
                  onChanged: (_) {
                    if (_preview != null) setState(() => _preview = null);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _validate,
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('PREVIEW & VALIDATE'),
                  ),
                ),
                if (preview != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    '$validCount of ${preview.length} row(s) look good',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: validCount == preview.length ? Colors.green[700] : Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...preview.map((row) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            row.isValid ? Icons.check_circle : Icons.error_outline,
                            color: row.isValid ? Colors.green : Colors.red,
                          ),
                          title: Text(
                            row.isValid ? row.ipo!.companyName : 'Line ${row.lineNumber}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            row.isValid
                                ? '${AppDateUtils.formatDateString(row.ipo!.openDate)} – '
                                    '${AppDateUtils.formatDateString(row.ipo!.closeDate)} · ${row.ipo!.ipoType}'
                                : row.error ?? 'Invalid row',
                            style: TextStyle(fontSize: 12, color: row.isValid ? null : Colors.red[700]),
                          ),
                        ),
                      )),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: (preview != null && validCount > 0)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _importing ? null : _importValidRows,
                    child: _importing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text('IMPORT $validCount IPO${validCount == 1 ? '' : 'S'}'),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
