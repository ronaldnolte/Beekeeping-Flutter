import 'package:flutter/material.dart';
import '../models/inspection.dart';

class AddInspectionDialog extends StatefulWidget {
  final Function(Inspection) onAdd;

  const AddInspectionDialog({super.key, required this.onAdd});

  @override
  State<AddInspectionDialog> createState() => _AddInspectionDialogState();
}

class _AddInspectionDialogState extends State<AddInspectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _tempController = TextEditingController(); // Simple string for now
  QueenStatus _queenStatus = QueenStatus.seen;
  final String _weather = "Sunny"; // Default, could be dropdown

  @override
  void dispose() {
    _notesController.dispose();
    _tempController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newInspection = Inspection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now().toIso8601String(),
        weather: _weather,
        temperature: _tempController.text.isNotEmpty ? _tempController.text : "N/A",
        queenStatus: _queenStatus,
        notes: _notesController.text,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      widget.onAdd(newInspection);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("New Inspection"),
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
                 DropdownButtonFormField<QueenStatus>(
                  value: _queenStatus,
                  decoration: const InputDecoration(labelText: "Queen Status"),
                  items: QueenStatus.values.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s == QueenStatus.cappedBrood ? "CAPPED BROOD" : s.name.toUpperCase()),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _queenStatus = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tempController,
                  decoration: const InputDecoration(labelText: "Temperature (°F)"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: "Notes"),
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
