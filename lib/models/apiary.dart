class Apiary {
  final String id;
  final String name;
  final String zipCode;
  final double? latitude;
  final double? longitude;
  final int createdAt;

  Apiary({
    required this.id,
    required this.name,
    required this.zipCode,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'zipCode': zipCode,
    'latitude': latitude,
    'longitude': longitude,
    'createdAt': createdAt,
  };

  factory Apiary.fromJson(Map<String, dynamic> json) => Apiary(
    id: json['id'],
    name: json['name'],
    zipCode: json['zipCode'],
    latitude: json['latitude'],
    longitude: json['longitude'],
    createdAt: json['createdAt'],
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Apiary && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
