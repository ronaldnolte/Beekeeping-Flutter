import 'package:flutter/material.dart';
import '../models/hive.dart';
import '../services/storage_service.dart';

class SelectHiveDialog extends StatefulWidget {
  final Function(Hive) onSelected;

  const SelectHiveDialog({super.key, required this.onSelected});

  @override
  State<SelectHiveDialog> createState() => _SelectHiveDialogState();
}

class _SelectHiveDialogState extends State<SelectHiveDialog> {
  final StorageService _storage = StorageService();
  List<Hive> _hives = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHives();
  }

  Future<void> _loadHives() async {
    final hives = await _storage.getHives();
    if (mounted) {
      setState(() {
        _hives = hives;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select a Hive"),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _hives.isEmpty
                ? const Text("No hives available. Create one first.")
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _hives.length,
                    itemBuilder: (context, index) {
                      final hive = _hives[index];
                      return ListTile(
                        title: Text(hive.name),
                        subtitle: Text(hive.location), // Display ID or name if mapped
                        onTap: () {
                          widget.onSelected(hive);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}
