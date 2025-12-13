import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/apiary.dart';
import '../models/hive.dart';
import '../models/intervention.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';

class InterventionsScreen extends StatefulWidget {
  const InterventionsScreen({super.key});

  @override
  State<InterventionsScreen> createState() => _InterventionsScreenState();
}

class _InterventionsScreenState extends State<InterventionsScreen> {
  final StorageService _storage = StorageService();
  bool _loading = true;
  List<Map<String, dynamic>> _flatInterventions = [];
  Apiary? _apiary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Apiary) {
      _apiary = args;
    }
    _loadInterventions();
  }

  Future<void> _loadInterventions() async {
    setState(() => _loading = true);
    final hives = await _storage.getHives();
    
    List<Map<String, dynamic>> temp = [];
    for (var hive in hives) {
       if (_apiary != null && (hive.location != _apiary!.id && hive.location != _apiary!.name)) {
        continue;
      }
      for (var intervention in hive.interventions) {
        temp.add({
          'intervention': intervention,
          'hiveName': hive.name,
          'hive': hive,
        });
      }
    }

    temp.sort((a, b) {
      final iA = a['intervention'] as Intervention;
      final iB = b['intervention'] as Intervention;
      return iB.createdAt.compareTo(iA.createdAt);
    });

    if (mounted) {
      setState(() {
        _flatInterventions = temp;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_apiary != null ? "Interventions - ${_apiary!.name}" : "All Interventions"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _flatInterventions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.stethoscope, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        "No interventions found",
                        style: TextStyle(color: Colors.grey[600], fontSize: 18),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _flatInterventions.length,
                  itemBuilder: (context, index) {
                    final item = _flatInterventions[index];
                    final intervention = item['intervention'] as Intervention;
                    final hiveName = item['hiveName'] as String;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.withOpacity(0.2),
                          child: const Icon(LucideIcons.pill, color: Colors.purple, size: 18),
                        ),
                        title: Text("${intervention.type.name.toUpperCase()} - $hiveName", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat.yMMMd().format(DateTime.parse(intervention.date))),
                            if (intervention.description.isNotEmpty) Text(intervention.description),
                          ],
                        ),
                        onTap: () {
                           Navigator.pushNamed(
                                context, 
                                '/hive_details', 
                                arguments: item['hive']
                              );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
