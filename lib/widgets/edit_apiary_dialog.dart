import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/apiary.dart';

class EditApiaryDialog extends StatefulWidget {
  final Apiary apiary;
  final Function(Apiary) onEdit;

  const EditApiaryDialog({super.key, required this.apiary, required this.onEdit});

  @override
  State<EditApiaryDialog> createState() => _EditApiaryDialogState();
}

class _EditApiaryDialogState extends State<EditApiaryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _zipController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.apiary.name);
    _zipController = TextEditingController(text: widget.apiary.zipCode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final updatedApiary = Apiary(
        id: widget.apiary.id,
        name: _nameController.text.trim(),
        zipCode: _zipController.text.trim(),
        createdAt: widget.apiary.createdAt,
      );
      widget.onEdit(updatedApiary);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Apiary"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Apiary Name",
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? "Please enter a name" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _zipController,
              decoration: const InputDecoration(
                labelText: "ZIP Code",
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
          child: const Text("Save"),
        ),
      ],
    );
  }
}
