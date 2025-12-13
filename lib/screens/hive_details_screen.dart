import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/hive.dart';
import '../models/inspection.dart';
import '../models/intervention.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';
import '../widgets/add_inspection_dialog.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/add_intervention_dialog.dart';
import '../utils/persistent_header_delegate.dart';

class HiveDetailsScreen extends StatefulWidget {
  const HiveDetailsScreen({super.key});

  @override
  State<HiveDetailsScreen> createState() => _HiveDetailsScreenState();
}

class _HiveDetailsScreenState extends State<HiveDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Hive _hive;
  bool _loadError = false;
  final StorageService _storage = StorageService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Hive) {
      _hive = args;
      _loadError = false;
    } else {
      _loadError = true;
    }
  }

  @override
  void initState() {
    super.initState();
    super.initState();
    // 3 Tabs: Inspections, Interventions, Tasks
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addInspection(Inspection inspection) async {
    setState(() {
      _hive.inspections.add(inspection);
      _hive.inspections.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
    await _storage.updateHive(_hive);
  }
  
  void _addTask(TaskModel task) async {
    setState(() {
      _hive.tasks.add(task);
      _hive.tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
    await _storage.updateHive(_hive);
  }

  void _addIntervention(Intervention intervention) async {
    setState(() {
      _hive.interventions.add(intervention);
      _hive.interventions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
    await _storage.updateHive(_hive);
  }
  
  void _toggleTask(TaskModel task) async {
    setState(() {
      task.completed = !task.completed;
    });
    await _storage.updateHive(_hive);
  }

  void _toggleActive() async {
    // Determine new status
    bool newStatus = !_hive.active;
    // We need to create a copy or update mutable hive. Assuming hive is mutable for now or we just update the field.
    // Since Hive fields are final, we theoretically need to recreate it, but let's check strictness. 
    // Dart lists are mutable, but boolean fields are final.
    // We should copyWith, but we didn't implement it. I'll construct a new Hive manually or cast.
    // For expediency in this migration, I will use a helper or manual dict copy.
    Map<String, dynamic> json = _hive.toJson();
    json['active'] = newStatus;
    Hive updated = Hive.fromJson(json);
    
    setState(() {
      _hive = updated;
    });
    await _storage.updateHive(_hive);
  }

  Future<void> _captureConfiguration() async {
    final snapshot = BarSnapshot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now().toIso8601String(),
      bars: _hive.bars.map((b) => Bar.fromJson(b.toJson())).toList(), // Deep copy
    );
    
    setState(() {
      _hive.snapshots.insert(0, snapshot); // Add to top
    });
    await _storage.updateHive(_hive);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Configuration captured!")));
    }
  }

  void _deleteSnapshot(BarSnapshot snapshot) async {
    setState(() {
      _hive.snapshots.removeWhere((s) => s.id == snapshot.id);
    });
    await _storage.updateHive(_hive);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Error"), 
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Hive details not found.\nThis can happen if you refresh the page."),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/hives'),
                child: const Text("Return to Hives List"),
              )
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: Column(
                children: [
                  Text(_hive.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("${_hive.barCount} bars", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
                ],
              ),
              centerTitle: false,
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              pinned: true,
              floating: true,
              forceElevated: innerBoxIsScrolled,
              actions: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _hive.active ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _hive.active ? "Active" : "Inactive",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _toggleActive,
                  style: TextButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                  child: Text(_hive.active ? "Mark as Inactive" : "Mark as Active"),
                ),
                const SizedBox(width: 16),
              ],
            ),
            SliverToBoxAdapter(
              child: _buildConfigurationSection(),
            ),
            SliverPersistentHeader(
              delegate: PersistentHeaderDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.secondary,
                  tabs: const [
                    Tab(text: "Inspections"),
                    Tab(text: "Interventions"),
                    Tab(text: "Tasks"),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInspectionsTab(),
            _buildInterventionsTab(),
            _buildTasksTab(),
          ],
        ),
      ),
    );
  }
  


  Widget _buildConfigurationSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar Configuration Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Top Bar Configuration", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Serif')), // Serif to match screenshot style roughly
                      OutlinedButton.icon(
                        icon: const Icon(LucideIcons.camera, size: 16),
                        label: const Text("Capture"),
                        onPressed: _captureConfiguration,
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Bars Visualizer
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _hive.bars.map((bar) {
                        return _buildBarItem(bar);
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  // Legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildLegendItem("Inactive", Colors.blueGrey.shade900),
                      _buildLegendItem("Active", Colors.blueGrey.shade400),
                      _buildLegendItem("Empty", Colors.white, border: true),
                      _buildLegendItem("Brood", const Color(0xFFC19A6B)), // Light brown/khaki
                      _buildLegendItem("Resource", Colors.amber),
                      _buildLegendItem("Follower Board", Colors.brown.shade900),
                    ],
                  )
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Configuration History Section
          const Text("Configuration History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Serif')),
          const SizedBox(height: 8),
          
          if (_hive.snapshots.isEmpty)
             const Center(child: Padding(padding: EdgeInsets.all(32), child: Text("No history recorded", style: TextStyle(color: Colors.grey)))),
             
          ..._hive.snapshots.map((snapshot) {
            return Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
              child: Row(
                  children: [
                    // Date
                    SizedBox(
                      width: 100, // Fixed width for alignment
                      child: Text(
                        DateFormat.yMMMd().format(DateTime.parse(snapshot.date)),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Bars Visualizer
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: snapshot.bars.map((bar) => _buildBarItem(bar, small: true)).toList(),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                      onPressed: () => _deleteSnapshot(snapshot),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  ],
                ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _cycleBarStatus(int index) {
    BarStatus currentStatus = _hive.bars[index].status;
    
    // Determine left neighbor (default to Empty if none)
    BarStatus leftNeighborStatus = (index > 0) ? _hive.bars[index - 1].status : BarStatus.empty; 

    // 1. Create standard rotated list starting with Left Neighbor
    List<BarStatus> cycleOrder = List.from(BarStatus.values);
    // Rotate list until leftNeighbor is at index 0
    while (cycleOrder.first != leftNeighborStatus) {
      cycleOrder.add(cycleOrder.removeAt(0));
    }
    
    // 2. Move 'Empty' to the very end of the list
    // This ensures Empty -> LeftNeighbor (Start of list)
    // And prevents Empty from appearing in the middle and disrupting flow
    cycleOrder.remove(BarStatus.empty);
    cycleOrder.add(BarStatus.empty);

    // 3. Find next status
    int currentIndex = cycleOrder.indexOf(currentStatus);
    int nextIndex = (currentIndex + 1) % cycleOrder.length;
    BarStatus targetStatus = cycleOrder[nextIndex];

    setState(() {
      _hive.bars[index].status = targetStatus;
    });
    
    _storage.updateHive(_hive);
  }

  Widget _buildBarItem(Bar bar, {bool small = false}) {
    final double width = small ? 10 : 35; 
    final double height = small ? 20 : 80; 
    
    return GestureDetector(
      onTap: small ? null : () => _cycleBarStatus(bar.number - 1),
      child: Container(
        width: width,
        height: height,
        margin: EdgeInsets.zero, // No padding
        decoration: BoxDecoration(
          color: _getBarColor(bar.status),
          border: Border.all(color: Colors.grey.shade300, width: 0.5), // Thinner border
        ),
        child: Center(
          child: Text(
            small ? "" : "${bar.number}",
            style: TextStyle(
              fontSize: small ? 8 : 10,
              color: bar.status == BarStatus.empty ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color, {bool border = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: border ? Border.all(color: Colors.grey.shade300) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _getBarColor(BarStatus status) {
    switch (status) {
      case BarStatus.brood: return const Color(0xFFC19A6B);
      case BarStatus.active: return Colors.blueGrey.shade400;
      case BarStatus.resource: return Colors.amber;
      case BarStatus.follower: return Colors.brown.shade900;
      case BarStatus.empty: return Colors.white; 
      case BarStatus.inactive: return Colors.blueGrey.shade900;
      default: return Colors.grey.shade200;
    }
  }

  Widget _buildInspectionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                 showDialog(
                   context: context,
                   builder: (_) => AddInspectionDialog(onAdd: _addInspection),
                 );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Add Inspection"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA0522D),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_hive.inspections.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.fileSearch, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("No inspections recorded yet.", style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                 constraints: const BoxConstraints(minWidth: 800), // Force minimum width for table look
                 child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Weather", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Temp", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Queen Status", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Notes", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  ],
                  rows: _hive.inspections.map((insp) {
                    return DataRow(cells: [
                      DataCell(Text(DateFormat.yMMMd().format(DateTime.parse(insp.date)))),
                      DataCell(Text(insp.weather)),
                      DataCell(Text("${insp.temperature}°F")),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getQueenStatusColor(insp.queenStatus).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getQueenStatusColor(insp.queenStatus)),
                          ),
                          child: Text(
                            insp.queenStatus == QueenStatus.cappedBrood ? "CAPPED BROOD" : insp.queenStatus.name.toUpperCase(),
                            style: TextStyle(
                              color: _getQueenStatusColor(insp.queenStatus),
                              fontSize: 10,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        )
                      ),
                      DataCell(SizedBox(width: 200, child: Text(insp.notes, overflow: TextOverflow.ellipsis))),
                      DataCell(
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _hive.inspections.remove(insp);
                                });
                                _storage.updateHive(_hive);
                              },
                            ),
                            // Edit functionality could be added here
                          ],
                        )
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInterventionsTab() {
     return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                 showDialog(
                   context: context,
                   builder: (_) => AddInterventionDialog(onAdd: _addIntervention),
                 );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Add Intervention"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_hive.interventions.isEmpty)
             const Center(child: Padding(padding: EdgeInsets.all(32), child: Text("No interventions recorded", style: TextStyle(color: Colors.grey))))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                 constraints: const BoxConstraints(minWidth: 600),
                 child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Type", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Description", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    ],
                    rows: _hive.interventions.map((intervention) {
                      return DataRow(cells: [
                        DataCell(Text(DateFormat.yMMMd().format(DateTime.parse(intervention.date)))),
                        DataCell(
                          Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(
                               color: Colors.grey.shade200, 
                               borderRadius: BorderRadius.circular(12)
                             ),
                             child: Text(intervention.type.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))
                          )
                        ),
                        DataCell(SizedBox(width: 250, child: Text(intervention.description, overflow: TextOverflow.ellipsis))),
                        DataCell(
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _hive.interventions.remove(intervention);
                                  });
                                  _storage.updateHive(_hive);
                                },
                              ),
                            ],
                          )
                        ),
                      ]);
                    }).toList(),
                 ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
     if (_hive.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.checkSquare, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("No tasks recorded", style: TextStyle(color: Colors.grey, fontSize: 18)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _hive.tasks.length,
      itemBuilder: (context, index) {
        final task = _hive.tasks[index];
        return Card(
          child: ListTile(
            leading: Checkbox(
              value: task.completed,
              onChanged: (_) => _toggleTask(task),
            ),
             title: Text(task.title, style: TextStyle(
              decoration: task.completed ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.bold
            )),
            subtitle: task.description.isNotEmpty ? Text(task.description) : null,
            trailing: IconButton(
               icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.grey),
               onPressed: () {
                 // Simple delete for tasks not yet impl in main overview screen, adding here for completeness
                 setState(() {
                   _hive.tasks.removeAt(index);
                 });
                 _storage.updateHive(_hive);
               },
            ),
          ),
        );
      },
    );
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
}
