enum QueenStatus { seen, eggs, cappedBrood, none }

class Inspection {
  final String id;
  final String date;
  final String weather;
  final String temperature;
  final QueenStatus queenStatus;
  final String notes;
  final int createdAt;

  Inspection({
    required this.id,
    required this.date,
    required this.weather,
    required this.temperature,
    required this.queenStatus,
    required this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'weather': weather,
        'temperature': temperature,
        'queenStatus': queenStatus.name, // Serialize enum as string name
        'notes': notes,
        'createdAt': createdAt,
      };

  factory Inspection.fromJson(Map<String, dynamic> json) => Inspection(
        id: json['id'],
        date: json['date'],
        weather: json['weather'],
        temperature: json['temperature'],
        queenStatus: QueenStatus.values.firstWhere(
            (e) => e.name == json['queenStatus'],
            orElse: () => QueenStatus.none),
        notes: json['notes'],
        createdAt: json['createdAt'],
      );
}
