import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/todo.dart';

enum TodoFilter { all, active, completed }

class TodoStore extends ChangeNotifier {
  static const _key = 'todos_v1';

  final List<Todo> _todos = [];
  TodoFilter _filter = TodoFilter.all;

  TodoFilter get filter => _filter;
  int get total => _todos.length;
  int get completedCount => _todos.where((t) => t.done).length;
  int get activeCount => total - completedCount;
  double get progress => total == 0 ? 0 : completedCount / total;

  List<Todo> get visible {
    final list = switch (_filter) {
      TodoFilter.all => _todos,
      TodoFilter.active => _todos.where((t) => !t.done).toList(),
      TodoFilter.completed => _todos.where((t) => t.done).toList(),
    };
    return List.unmodifiable(list);
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final data = jsonDecode(raw) as List;
        _todos
          ..clear()
          ..addAll(data.map((e) => Todo.fromJson(e as Map<String, dynamic>)));
      }
    } catch (_) {
      // Corrupt or unavailable storage: start with an empty list.
    }
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(_todos.map((t) => t.toJson()).toList()));
    } catch (_) {}
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  void setFilter(TodoFilter f) {
    _filter = f;
    notifyListeners();
  }

  void add(String title, Priority priority) {
    _todos.insert(
      0,
      Todo(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title.trim(),
        priority: priority,
      ),
    );
    _changed();
  }

  void update(String id, String title, Priority priority) {
    final i = _todos.indexWhere((t) => t.id == id);
    if (i == -1) return;
    _todos[i] = _todos[i].copyWith(title: title.trim(), priority: priority);
    _changed();
  }

  void toggle(String id) {
    final i = _todos.indexWhere((t) => t.id == id);
    if (i == -1) return;
    _todos[i] = _todos[i].copyWith(done: !_todos[i].done);
    _changed();
  }

  /// Removes a todo and returns it with its index so it can be restored.
  (Todo, int)? remove(String id) {
    final i = _todos.indexWhere((t) => t.id == id);
    if (i == -1) return null;
    final removed = _todos.removeAt(i);
    _changed();
    return (removed, i);
  }

  void restore(Todo todo, int index) {
    _todos.insert(index.clamp(0, _todos.length), todo);
    _changed();
  }

  void clearCompleted() {
    _todos.removeWhere((t) => t.done);
    _changed();
  }
}
