import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/main.dart';
import 'package:todo_app/models/todo.dart';
import 'package:todo_app/state/todo_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('store adds, toggles, filters and removes', () {
    final store = TodoStore();
    store.add('Write tests', Priority.high);
    store.add('Ship it', Priority.low);
    expect(store.total, 2);

    store.toggle(store.visible.first.id);
    expect(store.completedCount, 1);

    store.setFilter(TodoFilter.active);
    expect(store.visible.length, 1);

    store.setFilter(TodoFilter.all);
    final removed = store.remove(store.visible.first.id)!;
    expect(store.total, 1);
    store.restore(removed.$1, removed.$2);
    expect(store.total, 2);
  });

  testWidgets('empty state then add a task via the sheet', (tester) async {
    await tester.pumpWidget(TodoApp(store: TodoStore()));
    expect(find.text('No tasks yet'), findsOneWidget);

    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Buy milk');
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('No tasks yet'), findsNothing);
  });
}
