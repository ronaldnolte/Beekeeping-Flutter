import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/apiary.dart';
import '../models/hive.dart';
import '../models/inspection.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';

import '../widgets/select_hive_dialog.dart';
import '../widgets/add_inspection_dialog.dart';

class InspectionsScreen extends StatefulWidget {
  const InspectionsScreen({super.key});

  @override
  State<InspectionsScreen> createState() => _InspectionsScreenState();
}

class _InspectionsScreenState extends State<InspectionsScreen> {
  final StorageService _storage = StorageService();
  bool _loading = true;
  List<Map<String, dynamic>> _flatInspections = []; // {inspection, hiveName}
  Apiary? _apiary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Apiary) {
      _apiary = args;
    }
    _loadInspections();
  }

  Future<void> _loadInspections() async {
    setState(() => _loading = true);
    final hives = await _storage.getHives();
    
    List<Map<String, dynamic>> temp = [];
    for (var hive in hives) {
      // Filter by apiary if selected
      if (_apiary != null && (hive.location != _apiary!.id && hive.location != _apiary!.name)) {
        continue;
      }

      for (var insp in hive.inspections) {
        temp.add({
          'inspection': insp,
          'hiveName': hive.name,
          'hive': hive, // For navigation if needed
        });
      }
    }

    // Sort by date desc
    temp.sort((a, b) {
      final iA = a['inspection'] as Inspection;
      final iB = b['inspection'] as Inspection;
      return iB.createdAt.compareTo(iA.createdAt);
    });

    if (mounted) {
      setState(() {
        _flatInspections = temp;
        _loading = false;
      });
    }
  }

  Color _getQueenStatusColor(QueenStatus status) {
    if (status == QueenStatus.seen) {
      return Colors.green;
    }
    if (status == QueenStatus.eggs) {
      return Colors.blue;
    }
    if (status == QueenStatus.cappedBrood) {
      return Colors.orange;
    }
    return Colors.red;
  }

  void _startAddInspection() {
    showDialog(
      context: context,
      builder: (_) => SelectHiveDialog(
        onSelected: (hive) {
          // After selecting hive, show add dialog
          showDialog(
            context: context,
            builder: (_) => AddInspectionDialog(
              onAdd: (inspection) => _saveInspection(hive, inspection),
            ),
          );
        },
      ),
    );
  }

  void _saveInspection(Hive hive, Inspection inspection) async {
    hive.inspections.add(inspection);
    hive.inspections.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    await _storage.updateHive(hive);
    _loadInspections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_apiary != null ? "Inspections - ${_apiary!.name}" : "All Inspections"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _flatInspections.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.clipboardList, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        "No inspections found",
                        style: TextStyle(color: Colors.grey[600], fontSize: 18),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _flatInspections.length,
                  itemBuilder: (context, index) {
                    final item = _flatInspections[index];
                    final insp = item['inspection'] as Inspection;
                    final hiveName = item['hiveName'] as String;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getQueenStatusColor(insp.queenStatus).withOpacity(0.2),
                          child: Icon(LucideIcons.crown, size: 18, color: _getQueenStatusColor(insp.queenStatus)),
                        ),
                        title: Text("$hiveName - ${DateFormat.yMMMd().format(DateTime.parse(insp.date))}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(insp.notes, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Text("${insp.temperature}°F"),
                        onTap: () {
                          // Navigate to hive details?
                          Navigator.pushNamed(
                            context, 
                            '/hive_details', 
                            arguments: item['hive']
                          ).then((_) => _loadInspections());
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startAddInspection,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Log Inspection", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

