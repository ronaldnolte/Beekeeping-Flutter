class TaskModel {
  final String id;
  final String title;
  final String description;
  final String? dueDate;
  bool completed;
  final int createdAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    this.dueDate,
    required this.completed,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'dueDate': dueDate,
        'completed': completed,
        'createdAt': createdAt,
      };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        dueDate: json['dueDate'],
        completed: json['completed'],
        createdAt: json['createdAt'],
      );
}
