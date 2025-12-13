import 'package:flutter/material.dart';
import '../models/hive.dart';

class EditHiveDialog extends StatefulWidget {
  final Hive hive;
  final Function(Hive) onSave;

  const EditHiveDialog({
    super.key,
    required this.hive,
    required this.onSave,
  });

  @override
  State<EditHiveDialog> createState() => _EditHiveDialogState();
}

class _EditHiveDialogState extends State<EditHiveDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late int _barCount;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.hive.name);
    _barCount = widget.hive.barCount;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Logic for bar resizing could be complex (truncating vs adding).
      // For now, we'll just allow renaming and basic resizing (appending empty or truncating from end)
      
      List<Bar> newBars = List.from(widget.hive.bars);
      if (_barCount > newBars.length) {
        // Add
        int diff = _barCount - newBars.length;
        for (int i = 0; i < diff; i++) {
          newBars.add(Bar(number: newBars.length + 1, status: BarStatus.empty));
        }
      } else if (_barCount < newBars.length) {
        // Remove (truncate)
        newBars = newBars.sublist(0, _barCount);
      }

      final updatedHive = Hive(
        id: widget.hive.id,
        name: _nameController.text,
        location: widget.hive.location,
        barCount: _barCount,
        bars: newBars,
        inspections: widget.hive.inspections,
        interventions: widget.hive.interventions,
        tasks: widget.hive.tasks,
        snapshots: widget.hive.snapshots,
        active: widget.hive.active,
        createdAt: widget.hive.createdAt,
      );
      
      widget.onSave(updatedHive);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Hive"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Hive Name"),
              validator: (val) => val == null || val.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 16),
             Row(
              children: [
                const Text("Bar Count:"),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: [10, 20, 30, 40, 50].contains(_barCount) ? _barCount : null, // Handle custom counts if needed later
                  hint: Text("$_barCount"),
                  items: [10, 20, 30, 40, 50].map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.toString()),
                  )).toList(), 
                  onChanged: (val) {
                    if (val != null) setState(() => _barCount = val);
                  }
                )
              ],
            )
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: _submit, child: const Text("Save")),
      ],
    );
  }
}
