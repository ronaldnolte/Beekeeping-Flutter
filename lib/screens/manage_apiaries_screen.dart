import 'package:flutter/material.dart';
import '../models/apiary.dart';
import '../services/storage_service.dart';
import '../widgets/add_apiary_dialog.dart';
import '../widgets/edit_apiary_dialog.dart';
import '../utils/theme.dart';

class ManageApiariesScreen extends StatefulWidget {
  const ManageApiariesScreen({super.key});

  @override
  State<ManageApiariesScreen> createState() => _ManageApiariesScreenState();
}

class _ManageApiariesScreenState extends State<ManageApiariesScreen> {
  final StorageService _storage = StorageService();
  List<Apiary> _apiaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApiaries();
  }

  Future<void> _loadApiaries() async {
    setState(() => _isLoading = true);
    try {
      final apiaries = await _storage.getApiaries();
      setState(() {
        _apiaries = apiaries;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading apiaries: $e"), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addApiary(Apiary apiary) async {
    try {
      await _storage.addApiary(apiary);
      _loadApiaries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Apiary added")),
        );
      }
    } catch (e) {
      _showError("Error adding apiary: $e");
    }
  }

  Future<void> _editApiary(Apiary apiary) async {
    try {
      await _storage.updateApiary(apiary);
      _loadApiaries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Apiary updated")),
        );
      }
    } catch (e) {
      _showError("Error updating apiary: $e");
    }
  }

  Future<void> _deleteApiary(Apiary apiary) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Apiary"),
        content: Text("Are you sure you want to delete '${apiary.name}'?\n\nAny hives in this apiary will be moved to 'Unassigned'."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _storage.removeApiary(apiary.id);
        _loadApiaries();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Apiary deleted")),
          );
        }
      } catch (e) {
        _showError("Error deleting apiary: $e");
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Apiaries"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _apiaries.isEmpty
              ? const Center(child: Text("No apiaries found."))
              : ListView.builder(
                  itemCount: _apiaries.length,
                  itemBuilder: (context, index) {
                    final apiary = _apiaries[index];
                    return ListTile(
                      title: Text(apiary.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("ZIP: ${apiary.zipCode}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => EditApiaryDialog(
                                  apiary: apiary,
                                  onEdit: _editApiary,
                                ),
                              );
                            },
                          ),
                          if (apiary.zipCode != '00000')
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteApiary(apiary),
                            ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddApiaryDialog(onAdd: _addApiary),
          );
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
