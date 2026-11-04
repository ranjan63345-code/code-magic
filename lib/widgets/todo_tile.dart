import 'package:flutter/material.dart';

import '../models/todo.dart';

Color priorityColor(Priority p) => switch (p) {
      Priority.low => const Color(0xFF2E9E6B),
      Priority.medium => const Color(0xFFE59A1F),
      Priority.high => const Color(0xFFD94452),
    };

String priorityLabel(Priority p) => switch (p) {
      Priority.low => 'Low',
      Priority.medium => 'Medium',
      Priority.high => 'High',
    };

class TodoTile extends StatelessWidget {
  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = priorityColor(todo.priority);

    return Dismissible(
      key: ValueKey(todo.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
            child: Row(
              children: [
                Checkbox(
                  value: todo.done,
                  onChanged: (_) => onToggle(),
                  shape: const CircleBorder(),
                  side: BorderSide(color: color, width: 2),
                ),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: (text.bodyLarge ?? const TextStyle()).copyWith(
                      fontWeight: FontWeight.w500,
                      decoration:
                          todo.done ? TextDecoration.lineThrough : null,
                      color: todo.done
                          ? scheme.onSurface.withValues(alpha: 0.45)
                          : scheme.onSurface,
                    ),
                    child: Text(todo.title),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    priorityLabel(todo.priority),
                    style: text.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
