import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/account.dart';
import '../../providers/account_provider.dart';
import '../../utils/validators.dart';

class AddEditAccountScreen extends StatefulWidget {
  final Account? account;

  const AddEditAccountScreen({super.key, this.account});

  @override
  State<AddEditAccountScreen> createState() => _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends State<AddEditAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _holderNameController;
  late TextEditingController _nicknameController;
  late TextEditingController _panController;
  late TextEditingController _dpIdController;
  late TextEditingController _clientIdController;
  late TextEditingController _brokerNameController;
  late TextEditingController _notesController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final acc = widget.account;
    _holderNameController = TextEditingController(text: acc?.accountHolderName ?? '');
    _nicknameController = TextEditingController(text: acc?.accountNickname ?? '');
    _panController = TextEditingController(text: acc?.panNumber ?? '');
    _dpIdController = TextEditingController(text: acc?.dpId ?? '');
    _clientIdController = TextEditingController(text: acc?.clientId ?? '');
    _brokerNameController = TextEditingController(text: acc?.brokerName ?? '');
    _notesController = TextEditingController(text: acc?.notes ?? '');
  }

  @override
  void dispose() {
    _holderNameController.dispose();
    _nicknameController.dispose();
    _panController.dispose();
    _dpIdController.dispose();
    _clientIdController.dispose();
    _brokerNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final accountProvider = Provider.of<AccountProvider>(context, listen: false);

    final panUpper = _panController.text.trim().toUpperCase();

    final newAccount = Account(
      id: widget.account?.id,
      accountHolderName: _holderNameController.text.trim(),
      accountNickname: _nicknameController.text.trim(),
      panNumber: panUpper,
      dpId: _dpIdController.text.trim().isEmpty ? null : _dpIdController.text.trim(),
      clientId: _clientIdController.text.trim().isEmpty ? null : _clientIdController.text.trim(),
      brokerName: _brokerNameController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: widget.account?.createdAt,
    );

    bool success = false;
    if (widget.account == null) {
      success = await accountProvider.addAccount(newAccount);
    } else {
      success = await accountProvider.updateAccount(newAccount);
    }

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.account == null
                ? 'Account created successfully!'
                : 'Account updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accountProvider.errorMessage ?? 'Failed to save account'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Account' : 'Add Demat Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _holderNameController,
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name *',
                  hintText: 'e.g. Rahul Sharma',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: AppValidators.validateAccountHolderName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Account Nickname *',
                  hintText: 'e.g. My Account, Father, Mother',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: AppValidators.validateAccountNickname,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _panController,
                decoration: const InputDecoration(
                  labelText: 'PAN Number *',
                  hintText: 'ABCDE1234F',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 10,
                validator: AppValidators.validatePan,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brokerNameController,
                decoration: const InputDecoration(
                  labelText: 'Broker Name *',
                  hintText: 'e.g. Zerodha, Groww, Angel One',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
                validator: AppValidators.validateBrokerName,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dpIdController,
                      decoration: const InputDecoration(
                        labelText: 'DP ID (Optional)',
                        hintText: 'e.g. 12081600',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _clientIdController,
                      decoration: const InputDecoration(
                        labelText: 'Client ID (Optional)',
                        hintText: 'e.g. 01234567',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Additional account details or notes...',
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
                          : const Text('Save Account'),
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
}
