import 'package:flutter/material.dart';

import '../models/todo.dart';
import 'todo_tile.dart';

/// Bottom sheet for creating or editing a task.
Future<void> showTodoEditor(
  BuildContext context, {
  Todo? existing,
  required void Function(String title, Priority priority) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _EditorSheet(existing: existing, onSave: onSave),
  );
}

class _EditorSheet extends StatefulWidget {
  const _EditorSheet({this.existing, required this.onSave});

  final Todo? existing;
  final void Function(String title, Priority priority) onSave;

  @override
  State<_EditorSheet> createState() => _EditorSheetState();
}

class _EditorSheetState extends State<_EditorSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.existing?.title ?? '');
  late Priority _priority = widget.existing?.priority ?? Priority.medium;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Please enter a task title');
      return;
    }
    widget.onSave(title, _priority);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final editing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(editing ? 'Edit task' : 'New task',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              hintText: 'What needs to be done?',
              errorText: _error,
              prefixIcon: const Icon(Icons.edit_outlined),
            ),
          ),
          const SizedBox(height: 20),
          Text('Priority', style: text.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<Priority>(
            showSelectedIcon: false,
            segments: [
              for (final p in Priority.values)
                ButtonSegment(
                  value: p,
                  label: Text(priorityLabel(p)),
                  icon: Icon(Icons.flag_rounded,
                      size: 18, color: priorityColor(p)),
                ),
            ],
            selected: {_priority},
            onSelectionChanged: (s) => setState(() => _priority = s.first),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(editing ? 'Save changes' : 'Add task'),
            ),
          ),
        ],
      ),
    );
  }
}
