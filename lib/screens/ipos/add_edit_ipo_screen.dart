import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ipo.dart';
import '../../providers/ipo_provider.dart';
import '../../providers/registrar_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../utils/date_utils.dart';

class AddEditIpoScreen extends StatefulWidget {
  final Ipo? ipo;

  const AddEditIpoScreen({super.key, this.ipo});

  @override
  State<AddEditIpoScreen> createState() => _AddEditIpoScreenState();
}

class _AddEditIpoScreenState extends State<AddEditIpoScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyNameController;
  late TextEditingController _priceBandController;
  late TextEditingController _registrarNameController;
  late TextEditingController _registrarUrlController;
  late TextEditingController _notesController;
  late TextEditingController _gmpController;

  String _selectedIpoType = AppConstants.ipoTypeMainboard;
  String _selectedStatus = AppConstants.statusUpcoming;

  DateTime? _openDate;
  DateTime? _closeDate;
  DateTime? _allotmentDate;
  DateTime? _listingDate;

  bool _isSaving = false;
  TextEditingController? _autocompleteController;

  @override
  void initState() {
    super.initState();
    final ipo = widget.ipo;
    _companyNameController = TextEditingController(text: ipo?.companyName ?? '');
    _priceBandController = TextEditingController(text: ipo?.priceBand ?? '');
    _registrarNameController = TextEditingController(text: ipo?.registrarName ?? '');
    _registrarUrlController = TextEditingController(text: ipo?.registrarUrl ?? '');
    _notesController = TextEditingController(text: ipo?.notes ?? '');
    _gmpController = TextEditingController(text: ipo?.gmp ?? '');

    if (ipo != null) {
      _selectedIpoType = ipo.ipoType;
      _selectedStatus = ipo.ipoStatus;
      _openDate = AppDateUtils.parseDate(ipo.openDate);
      _closeDate = AppDateUtils.parseDate(ipo.closeDate);
      _allotmentDate = AppDateUtils.parseDate(ipo.allotmentDate);
      _listingDate = AppDateUtils.parseDate(ipo.listingDate);
    } else {
      _openDate = DateTime.now();
      _closeDate = DateTime.now().add(const Duration(days: 3));
      _allotmentDate = DateTime.now().add(const Duration(days: 6));
      _listingDate = DateTime.now().add(const Duration(days: 9));
      _recalculateStatus();
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _priceBandController.dispose();
    _registrarNameController.dispose();
    _registrarUrlController.dispose();
    _notesController.dispose();
    _gmpController.dispose();
    super.dispose();
  }

  void _recalculateStatus() {
    if (_openDate != null && _closeDate != null) {
      final openStr = AppDateUtils.toIsoDate(_openDate);
      final closeStr = AppDateUtils.toIsoDate(_closeDate);
      final allotmentStr = _allotmentDate != null ? AppDateUtils.toIsoDate(_allotmentDate) : null;
      final listingStr = _listingDate != null ? AppDateUtils.toIsoDate(_listingDate) : null;
      setState(() {
        _selectedStatus = Ipo.calculateSuggestedStatus(openStr, closeStr, allotmentStr, listingStr);
      });
    }
  }

  Future<void> _selectDate(BuildContext context, String field) async {
    DateTime initial = DateTime.now();
    if (field == 'OPEN' && _openDate != null) initial = _openDate!;
    if (field == 'CLOSE' && _closeDate != null) initial = _closeDate!;
    if (field == 'ALLOTMENT' && _allotmentDate != null) initial = _allotmentDate!;
    if (field == 'LISTING' && _listingDate != null) initial = _listingDate!;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (field == 'OPEN') _openDate = picked;
        if (field == 'CLOSE') _closeDate = picked;
        if (field == 'ALLOTMENT') _allotmentDate = picked;
        if (field == 'LISTING') _listingDate = picked;
      });
      _recalculateStatus();
    }
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_openDate == null || _closeDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Open and Close dates')),
      );
      return;
    }

    if (_closeDate!.isBefore(_openDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Close date cannot be before Open date')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final ipoProvider = Provider.of<IpoProvider>(context, listen: false);

    final newIpo = Ipo(
      id: widget.ipo?.id,
      companyName: _companyNameController.text.trim(),
      ipoType: _selectedIpoType,
      priceBand: _priceBandController.text.trim(),
      openDate: AppDateUtils.toIsoDate(_openDate),
      closeDate: AppDateUtils.toIsoDate(_closeDate),
      allotmentDate: _allotmentDate != null ? AppDateUtils.toIsoDate(_allotmentDate) : null,
      listingDate: _listingDate != null ? AppDateUtils.toIsoDate(_listingDate) : null,
      registrarName: _registrarNameController.text.trim().isEmpty ? null : _registrarNameController.text.trim(),
      registrarUrl: _registrarUrlController.text.trim().isEmpty ? null : _registrarUrlController.text.trim(),
      ipoStatus: _selectedStatus,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      externalSlug: widget.ipo?.externalSlug,
      gmp: _gmpController.text.trim().isEmpty ? null : _gmpController.text.trim(),
    );

    bool success = false;
    if (widget.ipo == null) {
      success = await ipoProvider.addIpo(newIpo);
    } else {
      success = await ipoProvider.updateIpo(newIpo);
    }

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.ipo == null ? 'IPO created successfully' : 'IPO updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ipoProvider.errorMessage ?? 'Failed to save IPO'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final registrarProvider = Provider.of<RegistrarProvider>(context);
    final isEditing = widget.ipo != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit IPO' : 'Add New IPO'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name *',
                  hintText: 'e.g. ABC Limited',
                  prefixIcon: Icon(Icons.business),
                ),
                textCapitalization: TextCapitalization.words,
                validator: AppValidators.validateCompanyName,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedIpoType,
                      decoration: const InputDecoration(
                        labelText: 'IPO Type *',
                      ),
                      items: AppConstants.ipoTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedIpoType = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceBandController,
                      decoration: const InputDecoration(
                        labelText: 'Price Band *',
                        hintText: 'e.g. ₹450 - ₹475',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter price band' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gmpController,
                decoration: const InputDecoration(
                  labelText: 'GMP (Grey Market Premium)',
                  hintText: 'e.g. ₹45 (unofficial rumour)',
                  helperText: 'Optional — unofficial market chatter, not verified data. Type what you heard.',
                  helperMaxLines: 2,
                  prefixIcon: Icon(Icons.trending_up),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'IMPORTANT DATES',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField('Open Date *', _openDate, () => _selectDate(context, 'OPEN')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField('Close Date *', _closeDate, () => _selectDate(context, 'CLOSE')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField('Allotment Date', _allotmentDate, () => _selectDate(context, 'ALLOTMENT')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField('Listing Date', _listingDate, () => _selectDate(context, 'LISTING')),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'IPO Status *',
                  helperText: 'Suggested automatically based on dates',
                ),
                items: AppConstants.ipoStatuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.replaceAll('_', ' ')),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedStatus = val);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'REGISTRAR INFORMATION',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              // Registrar Dropdown / Free text
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final list = registrarProvider.registrars.map((r) => r.name).toList();
                  if (textEditingValue.text.isEmpty) return list;
                  return list.where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                initialValue: TextEditingValue(text: _registrarNameController.text),
                onSelected: (String selection) {
                  _registrarNameController.text = selection;
                  final match = registrarProvider.registrars.firstWhere((r) => r.name == selection);
                  _registrarUrlController.text = match.url;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  // Attach the sync listener only once per underlying controller
                  // instance, otherwise every rebuild (date picks, dropdown
                  // changes, etc.) would stack another duplicate listener.
                  if (_autocompleteController != controller) {
                    _autocompleteController = controller;
                    controller.addListener(() {
                      _registrarNameController.text = controller.text;
                    });
                  }
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Registrar Name',
                      hintText: 'e.g. Link Intime India',
                      prefixIcon: Icon(Icons.link),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _registrarUrlController,
                decoration: const InputDecoration(
                  labelText: 'Registrar Website / Allotment URL',
                  hintText: 'https://linkintime.co.in',
                  prefixIcon: Icon(Icons.language),
                ),
                validator: AppValidators.validateUrl,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Lot size, GMP, analysis notes...',
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
                      onPressed: _isSaving ? null : _saveForm,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Save IPO'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_month, size: 20),
        ),
        child: Text(
          date != null ? AppDateUtils.formatDate(date) : 'Select Date',
          style: TextStyle(
            fontSize: 14,
            color: date != null ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  }
}
