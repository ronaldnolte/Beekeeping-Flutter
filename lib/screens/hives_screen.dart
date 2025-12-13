import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/apiary.dart';
import '../models/hive.dart';
import '../models/inspection.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';
import '../widgets/add_hive_dialog.dart';
import '../widgets/edit_hive_dialog.dart';

class HivesScreen extends StatefulWidget {
  const HivesScreen({super.key});

  @override
  State<HivesScreen> createState() => _HivesScreenState();
}

class _HivesScreenState extends State<HivesScreen> {
  final StorageService _storage = StorageService();
  List<Hive> _hives = [];
  bool _loading = true;
  Apiary? _apiary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Apiary) {
      _apiary = args;
    }
    _loadHives();
  }

  Future<void> _loadHives() async {
    setState(() => _loading = true);
    final allHives = await _storage.getHives();
    if (mounted) {
      setState(() {
        if (_apiary != null) {
          _hives = allHives.where((h) => h.location == _apiary!.id || h.location == _apiary!.name).toList();
        } else {
          _hives = allHives;
        }
        _loading = false;
      });
    }
  }

  void _addHive(Hive hive) async {
    await _storage.addHive(hive);
    _loadHives();
  }

  void _updateHive(Hive hive) async {
    await _storage.updateHive(hive);
    _loadHives();
  }
  
  void _deleteHive(String id) async {
    await _storage.deleteHive(id);
    _loadHives();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_apiary != null ? "Hives - ${_apiary!.name}" : "All Hives"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
           if (_apiary != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA0522D), // Sienna/Brown
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddHiveDialog(
                      apiaryId: _apiary!.id,
                      onAdd: _addHive,
                    ),
                  );
                },
                child: const Text("Add New Hive"),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hives.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.home, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        "No hives found",
                        style: TextStyle(color: Colors.grey[600], fontSize: 18),
                      ),
                      if (_apiary == null)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Select an apiary on Home to add hives, or add generic ones here (not recommended).", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        )
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 500,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 280, 
                      ),
                      itemCount: _hives.length,
                      itemBuilder: (context, index) {
                        final hive = _hives[index];
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            hive.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _apiary?.name ?? hive.location,
                                            style: const TextStyle(color: Colors.grey),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(LucideIcons.edit3, size: 18, color: Colors.grey),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => EditHiveDialog(
                                                hive: hive,
                                                onSave: _updateHive,
                                              ),
                                            );
                                          },
                                          tooltip: "Edit",
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                                          label: const Text("Delete", style: TextStyle(color: Colors.red)),
                                          onPressed: () => _showDeleteConfirm(hive.id),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                const SizedBox(height: 16),
                                // Attributes List
                                _buildAttributeRow("Status", hive.active ? "Active" : "Inactive", 
                                    valueColor: hive.active ? Colors.green : Colors.red),
                                const SizedBox(height: 8),
                                _buildAttributeRow("Bars", "${hive.barCount}"),
                                const SizedBox(height: 8),
                                _buildAttributeRow("Last Inspection", _getLastInspectionDate(hive)),
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFA0522D), // Sienna/Brown
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context, 
                                        '/hive_details', 
                                        arguments: hive
                                      ).then((_) => _loadHives());
                                    },
                                    child: const Text("View Hive"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
  
  void _showDeleteConfirm(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Hive?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(ctx)),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)), 
            onPressed: () {
              Navigator.pop(ctx);
              _deleteHive(id);
            }
          ),
        ],
      ),
    );
  }


  Widget _buildAttributeRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        Text(
          value, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: valueColor ?? Colors.black87
          )
        ),
      ],
    );
  }

  String _getLastInspectionDate(Hive hive) {
    if (hive.inspections.isEmpty) return "Never";
    // Assuming inspections are sorted desc by default or we sort them here
    final sorted = List<Inspection>.from(hive.inspections)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    final last = sorted.first;
    // Format: MM/dd/yyyy using DateTime methods manually to match requested format
    final date = DateTime.parse(last.date);
    return "${date.month}/${date.day}/${date.year}"; 
  }
}
