import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/registrar.dart';
import '../../providers/registrar_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/empty_state.dart';

class RegistrarLinksScreen extends StatelessWidget {
  const RegistrarLinksScreen({super.key});

  void _showAddEditDialog(BuildContext context, [Registrar? registrar]) {
    final isEditing = registrar != null;
    final nameController = TextEditingController(text: registrar?.name ?? '');
    final urlController = TextEditingController(text: registrar?.url ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEditing ? 'Edit Registrar' : 'Add Registrar Link'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Registrar Name *',
                  hintText: 'e.g. Link Intime India',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Website / Allotment URL *',
                  hintText: 'https://linkintime.co.in',
                ),
                validator: AppValidators.validateUrl,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final provider = Provider.of<RegistrarProvider>(context, listen: false);

              final newReg = Registrar(
                id: registrar?.id,
                name: nameController.text.trim(),
                url: urlController.text.trim(),
              );

              bool success = false;
              if (isEditing) {
                success = await provider.updateRegistrar(newReg);
              } else {
                success = await provider.addRegistrar(newReg);
              }

              if (ctx.mounted) Navigator.pop(ctx);

              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? 'Registrar updated' : 'Registrar added'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ?? 'Operation failed'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _deleteRegistrar(BuildContext context, Registrar registrar) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Registrar Link?',
      content: 'Are you sure you want to delete ${registrar.name}?',
      confirmLabel: 'DELETE',
      cancelLabel: 'CANCEL',
      confirmColor: Colors.red,
    );

    if (confirmed && context.mounted) {
      final provider = Provider.of<RegistrarProvider>(context, listen: false);
      final success = await provider.deleteRegistrar(registrar.id!);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registrar deleted')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final registrarProvider = Provider.of<RegistrarProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Official Registrar Links'),
      ),
      body: registrarProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : registrarProvider.registrars.isEmpty
              ? EmptyState(
                  icon: Icons.link_off,
                  title: 'No Registrars Added',
                  message: 'Add official IPO registrar links for quick status checking.',
                  actionLabel: 'Add Registrar',
                  onAction: () => _showAddEditDialog(context),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: registrarProvider.registrars.length,
                  itemBuilder: (context, index) {
                    final reg = registrarProvider.registrars[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(Icons.language, color: Theme.of(context).primaryColor),
                        ),
                        title: Text(
                          reg.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          reg.url,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.open_in_new, color: Colors.teal),
                              tooltip: 'Open Website',
                              onPressed: () {
                                RegistrarProvider.launchRegistrarUrl(reg.url);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showAddEditDialog(context, reg),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.grey),
                              onPressed: () => _deleteRegistrar(context, reg),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Registrar'),
      ),
    );
  }
}
