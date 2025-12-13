import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/intervention.dart';

class AddInterventionDialog extends StatefulWidget {
  final Function(Intervention) onAdd;

  const AddInterventionDialog({super.key, required this.onAdd});

  @override
  State<AddInterventionDialog> createState() => _AddInterventionDialogState();
}

class _AddInterventionDialogState extends State<AddInterventionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  InterventionType _type = InterventionType.feeding;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newIntervention = Intervention(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: _selectedDate.toIso8601String(),
        type: _type,
        description: _descController.text,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      widget.onAdd(newIntervention);
      Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("New Intervention"),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date Picker
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Date",
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat.yMMMd().format(_selectedDate)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Type Dropdown
                DropdownButtonFormField<InterventionType>(
                  value: _type,
                  decoration: const InputDecoration(labelText: "Type"),
                  items: InterventionType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _type = val);
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    hintText: "Details about the intervention...",
                  ),
                  maxLines: 3,
                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                ),
              ],
            ),
          ),
        ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: _submit, child: const Text("Save")),
      ],
    );
  }
}
