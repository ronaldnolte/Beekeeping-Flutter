import 'inspection.dart';
import 'intervention.dart';
import 'task_model.dart';

enum BarStatus { inactive, active, empty, brood, resource, follower }

class Bar {
  final int number;
  BarStatus status;
  String? notes;

  Bar({
    required this.number,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'number': number,
        'status': status.name,
        'notes': notes,
      };

  factory Bar.fromJson(Map<String, dynamic> json) => Bar(
        number: json['number'],
        status: BarStatus.values.firstWhere(
            (e) => e.name == json['status'],
            orElse: () => BarStatus.inactive),
        notes: json['notes'],
      );
}

class BarSnapshot {
  final String id;
  final String date;
  final List<Bar> bars;

  BarSnapshot({
    required this.id,
    required this.date,
    required this.bars,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'bars': bars.map((b) => b.toJson()).toList(),
      };

  factory BarSnapshot.fromJson(Map<String, dynamic> json) => BarSnapshot(
        id: json['id'],
        date: json['date'],
        bars: (json['bars'] as List<dynamic>)
            .map((e) => Bar.fromJson(e))
            .toList(),
      );
}

class Hive {
  final String id;
  final String name;
  final String location;
  final int barCount;
  final List<Bar> bars;
  final List<Inspection> inspections;
  final List<Intervention> interventions;
  final List<TaskModel> tasks;
  final List<BarSnapshot> snapshots;
  final bool active;
  final int createdAt;

  Hive({
    required this.id,
    required this.name,
    required this.location,
    required this.barCount,
    required this.bars,
    required this.inspections,
    required this.interventions,
    required this.tasks,
    required this.snapshots,
    required this.active,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'barCount': barCount,
        'bars': bars.map((b) => b.toJson()).toList(),
        'inspections': inspections.map((i) => i.toJson()).toList(),
        'interventions': interventions.map((i) => i.toJson()).toList(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'snapshots': snapshots.map((s) => s.toJson()).toList(),
        'active': active,
        'createdAt': createdAt,
      };

  factory Hive.fromJson(Map<String, dynamic> json) => Hive(
        id: json['id'],
        name: json['name'],
        location: json['location'],
        barCount: json['barCount'],
        bars: (json['bars'] as List<dynamic>?)
                ?.map((e) => Bar.fromJson(e))
                .toList() ??
            [],
        inspections: (json['inspections'] as List<dynamic>?)
                ?.map((e) => Inspection.fromJson(e))
                .toList() ??
            [],
        interventions: (json['interventions'] as List<dynamic>?)
                ?.map((e) => Intervention.fromJson(e))
                .toList() ??
            [],
        tasks: (json['tasks'] as List<dynamic>?)
                ?.map((e) => TaskModel.fromJson(e))
                .toList() ??
            [],
        snapshots: (json['snapshots'] as List<dynamic>?)
                ?.map((e) => BarSnapshot.fromJson(e))
                .toList() ??
            [],
        active: json['active'] ?? true,
        createdAt: json['createdAt'],
      );
      
  /// Helper to create a new hive with default bars
  factory Hive.create({
    required String id,
    required String name,
    required String location,
    required int barCount,
  }) {
    List<Bar> initialBars = List.generate(barCount, (index) => Bar(
      number: index + 1, 
      status: BarStatus.empty
    ));
    
    return Hive(
      id: id,
      name: name,
      location: location,
      barCount: barCount,
      bars: initialBars,
      inspections: [],
      interventions: [],
      tasks: [],
      snapshots: [],
      active: true,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
