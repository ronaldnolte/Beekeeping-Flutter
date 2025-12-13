import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/apiary.dart';
import '../services/storage_service.dart';

class AddApiaryDialog extends StatefulWidget {
  final Future<void> Function(Apiary) onAdd;

  const AddApiaryDialog({super.key, required this.onAdd});

  @override
  State<AddApiaryDialog> createState() => _AddApiaryDialogState();
}

class _AddApiaryDialogState extends State<AddApiaryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _zipController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      final apiary = Apiary(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        zipCode: _zipController.text.trim(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      try {
        await widget.onAdd(apiary);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        // Error is handled by parent, but we stop loading
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add New Apiary"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Apiary Name",
                hintText: "e.g., Backyard Hive",
              ),
              enabled: !_isSaving,
              validator: (value) =>
                  value == null || value.isEmpty ? "Please enter a name" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _zipController,
              decoration: const InputDecoration(
                labelText: "ZIP Code",
                hintText: "e.g., 12345",
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              enabled: !_isSaving,
              validator: (value) =>
                  value == null || value.length < 5 ? "Enter valid 5-digit ZIP" : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text("Add"),
        ),
      ],
    );
  }
}
