enum Priority { low, medium, high }

class Todo {
  Todo({
    required this.id,
    required this.title,
    this.priority = Priority.medium,
    this.done = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final Priority priority;
  final bool done;
  final DateTime createdAt;

  Todo copyWith({String? title, Priority? priority, bool? done}) => Todo(
        id: id,
        title: title ?? this.title,
        priority: priority ?? this.priority,
        done: done ?? this.done,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'priority': priority.name,
        'done': done,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as String,
        title: json['title'] as String,
        priority: Priority.values.firstWhere(
          (p) => p.name == json['priority'],
          orElse: () => Priority.medium,
        ),
        done: json['done'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}
