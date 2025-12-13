import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/apiary.dart';
import '../services/storage_service.dart';

class AddApiaryDialog extends StatefulWidget {
  final Function(Apiary) onAdd;

  const AddApiaryDialog({super.key, required this.onAdd});

  @override
  State<AddApiaryDialog> createState() => _AddApiaryDialogState();
}

class _AddApiaryDialogState extends State<AddApiaryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _zipController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final apiary = Apiary(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        zipCode: _zipController.text.trim(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      widget.onAdd(apiary);
      Navigator.pop(context);
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
              validator: (value) =>
                  value == null || value.length < 5 ? "Enter valid 5-digit ZIP" : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text("Add"),
        ),
      ],
    );
  }
}
