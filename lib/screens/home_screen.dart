import 'package:flutter/material.dart';

import '../state/todo_store.dart';
import '../widgets/todo_editor_sheet.dart';
import '../widgets/todo_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.store});

  final TodoStore store;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _dateLabel() {
    final d = DateTime.now();
    return '${_days[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final items = store.visible;

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showTodoEditor(
              context,
              onSave: store.add,
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New task'),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      greeting: _greeting(),
                      date: _dateLabel(),
                      store: store,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final f in TodoFilter.values) ...[
                                    ChoiceChip(
                                      label: Text(switch (f) {
                                        TodoFilter.all => 'All (${store.total})',
                                        TodoFilter.active =>
                                          'Active (${store.activeCount})',
                                        TodoFilter.completed =>
                                          'Done (${store.completedCount})',
                                      }),
                                      selected: store.filter == f,
                                      onSelected: (_) => store.setFilter(f),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (store.completedCount > 0)
                            IconButton(
                              tooltip: 'Clear completed',
                              icon: const Icon(Icons.cleaning_services_outlined),
                              onPressed: store.clearCompleted,
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: items.isEmpty
                          ? _EmptyState(filter: store.filter)
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 4, 20, 96),
                              itemCount: items.length,
                              itemBuilder: (context, i) {
                                final todo = items[i];
                                return TodoTile(
                                  todo: todo,
                                  onToggle: () => store.toggle(todo.id),
                                  onTap: () => showTodoEditor(
                                    context,
                                    existing: todo,
                                    onSave: (title, p) =>
                                        store.update(todo.id, title, p),
                                  ),
                                  onDelete: () {
                                    final removed = store.remove(todo.id);
                                    if (removed == null) return;
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    messenger
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        SnackBar(
                                          content: const Text('Task deleted'),
                                          action: SnackBarAction(
                                            label: 'Undo',
                                            textColor:
                                                scheme.inversePrimary,
                                            onPressed: () => store.restore(
                                                removed.$1, removed.$2),
                                          ),
                                        ),
                                      );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.date,
    required this.store,
  });

  final String greeting;
  final String date;
  final TodoStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final percent = (store.progress * 100).round();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primary, scheme.tertiary],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date,
                style: text.labelLarge
                    ?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.8))),
            const SizedBox(height: 4),
            Text(greeting,
                style: text.headlineSmall?.copyWith(
                    color: scheme.onPrimary, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              store.total == 0
                  ? 'Add your first task to get started.'
                  : store.activeCount == 0
                      ? 'All done. Great work!'
                      : '${store.activeCount} task${store.activeCount == 1 ? '' : 's'} left today',
              style: text.bodyMedium
                  ?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.9)),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: store.progress,
                      minHeight: 8,
                      backgroundColor:
                          scheme.onPrimary.withValues(alpha: 0.25),
                      valueColor:
                          AlwaysStoppedAnimation(scheme.onPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('$percent%',
                    style: text.labelLarge?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final TodoFilter filter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (icon, title, sub) = switch (filter) {
      TodoFilter.all => (
          Icons.checklist_rounded,
          'No tasks yet',
          'Tap "New task" to add your first one.'
        ),
      TodoFilter.active => (
          Icons.celebration_outlined,
          'Nothing left to do',
          'You have no active tasks.'
        ),
      TodoFilter.completed => (
          Icons.task_alt_rounded,
          'No completed tasks',
          'Finished tasks will show up here.'
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: scheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(title,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(sub,
                textAlign: TextAlign.center,
                style: text.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
