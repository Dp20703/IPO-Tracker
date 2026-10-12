import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ipo.dart';
import '../../models/account.dart';
import '../../models/application.dart';
import '../../providers/application_provider.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final Ipo ipo;
  final Account account;
  final IpoApplication application;

  const ApplicationDetailScreen({
    super.key,
    required this.ipo,
    required this.account,
    required this.application,
  });

  @override
  State<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  late bool _hasApplied;
  late int _lotsApplied;
  late String _applicationStatus;
  late String _allotmentStatus;
  late TextEditingController _sharesAllottedController;
  late TextEditingController _notesController;
  DateTime? _applicationDate;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final app = widget.application;
    _hasApplied = app.hasApplied;
    _lotsApplied = app.lotsApplied > 0 ? app.lotsApplied : 1;
    _applicationStatus = app.applicationStatus;
    _allotmentStatus = app.allotmentStatus;
    _sharesAllottedController = TextEditingController(text: app.sharesAllotted.toString());
    _notesController = TextEditingController(text: app.notes ?? '');
    _applicationDate = AppDateUtils.parseDate(app.applicationDate) ?? DateTime.now();
  }

  @override
  void dispose() {
    _sharesAllottedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveApplication() async {
    setState(() {
      _isSaving = true;
    });

    final provider = Provider.of<ApplicationProvider>(context, listen: false);

    final shares = int.tryParse(_sharesAllottedController.text.trim()) ?? 0;

    final updatedApp = widget.application.copyWith(
      ipoId: widget.ipo.id,
      accountId: widget.account.id,
      hasApplied: _hasApplied,
      lotsApplied: _hasApplied ? _lotsApplied : 1,
      applicationStatus: _hasApplied ? _applicationStatus : AppConstants.appStatusNotApplied,
      allotmentStatus: _hasApplied ? _allotmentStatus : AppConstants.allotmentNotApplied,
      sharesAllotted: _hasApplied ? shares : 0,
      applicationDate: _hasApplied ? AppDateUtils.toIsoDate(_applicationDate) : null,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    final success = await provider.saveApplication(updatedApp);

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application record saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to save application'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Application'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Card(
              color: Theme.of(context).primaryColor.withOpacity(0.06),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.ipo.companyName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Account: ${widget.account.accountNickname} (${widget.account.accountHolderName})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Broker: ${widget.account.brokerName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Has Applied Toggle Switch
            Card(
              child: SwitchListTile(
                title: const Text(
                  'Applied for IPO?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _hasApplied ? 'Marked as Applied' : 'Marked as Not Applied',
                  style: TextStyle(color: _hasApplied ? Colors.green : Colors.grey),
                ),
                value: _hasApplied,
                activeColor: Colors.green,
                onChanged: (val) {
                  setState(() {
                    _hasApplied = val;
                    if (val) {
                      _applicationStatus = AppConstants.appStatusSubmitted;
                      _allotmentStatus = AppConstants.allotmentPending;
                    } else {
                      _applicationStatus = AppConstants.appStatusNotApplied;
                      _allotmentStatus = AppConstants.allotmentNotApplied;
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            if (_hasApplied) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'APPLICATION DETAILS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      // Lots Applied Counter
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lots Applied',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: _lotsApplied > 1
                                    ? () => setState(() => _lotsApplied--)
                                    : null,
                              ),
                              Text(
                                '$_lotsApplied',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => setState(() => _lotsApplied++),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Application Status Dropdown
                      DropdownButtonFormField<String>(
                        value: _applicationStatus,
                        decoration: const InputDecoration(
                          labelText: 'Application Status',
                        ),
                        items: AppConstants.appStatuses.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.replaceAll('_', ' ')),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _applicationStatus = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Allotment Status Dropdown
                      DropdownButtonFormField<String>(
                        value: _allotmentStatus,
                        decoration: const InputDecoration(
                          labelText: 'Allotment Status',
                        ),
                        items: AppConstants.allotmentStatuses.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.replaceAll('_', ' ')),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _allotmentStatus = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      if (_allotmentStatus == AppConstants.allotmentAllotted) ...[
                        TextFormField(
                          controller: _sharesAllottedController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Shares Allotted',
                            hintText: 'e.g. 15',
                            prefixIcon: Icon(Icons.pie_chart),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Application Date Picker
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _applicationDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _applicationDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Application Date',
                            suffixIcon: Icon(Icons.calendar_today, size: 20),
                          ),
                          child: Text(
                            AppDateUtils.formatDate(_applicationDate),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add application reference number, UPI ID used...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveApplication,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Save Application'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
