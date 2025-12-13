import 'package:flutter/material.dart';
import '../models/hive.dart';
import '../services/storage_service.dart';

class AddHiveDialog extends StatefulWidget {
  final String apiaryId;
  final Function(Hive) onAdd;

  const AddHiveDialog({
    super.key,
    required this.apiaryId,
    required this.onAdd,
  });

  @override
  State<AddHiveDialog> createState() => _AddHiveDialogState();
}

class _AddHiveDialogState extends State<AddHiveDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _barCount = 30; // Default Top Bar Hive size often

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newHive = Hive.create(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple ID generation
        name: _nameController.text,
        location: widget.apiaryId,
        barCount: _barCount,
      );
      
      widget.onAdd(newHive);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add New Hive"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Hive Name",
                hintText: "e.g., Hive 1",
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text("Bar Count:"),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _barCount,
                  items: [10, 20, 30, 40, 50].map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.toString()),
                  )).toList(), 
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _barCount = val);
                    }
                  }
                )
              ],
            )
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
          child: const Text("Add Hive"),
        ),
      ],
    );
  }
}
