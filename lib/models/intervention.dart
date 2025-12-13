enum InterventionType { feeding, treatment, manipulation, other }

class Intervention {
  final String id;
  final String date;
  final InterventionType type;
  final String description;
  final int createdAt;

  Intervention({
    required this.id,
    required this.date,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'type': type.name,
        'description': description,
        'createdAt': createdAt,
      };

  factory Intervention.fromJson(Map<String, dynamic> json) => Intervention(
        id: json['id'],
        date: json['date'],
        type: InterventionType.values.firstWhere(
            (e) => e.name == json['type'],
            orElse: () => InterventionType.other),
        description: json['description'],
        createdAt: json['createdAt'],
      );
}
