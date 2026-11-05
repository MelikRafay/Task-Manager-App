import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/export_service.dart';
import '../state/app_state.dart';
import '../utils/constants.dart';
import '../widgets/task_tile.dart';
import 'settings_screen.dart';
import 'task_form_screen.dart';

enum _Menu { csv, pdf, email, settings }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  String? _category; // null = all

  static const _titles = ['Today', 'Completed', 'Repeated'];

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openForm([Task? task]) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
      );

  Future<void> _confirmDelete(Task t) async {
    final state = AppScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"${t.title}" will be removed permanently.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await state.deleteTask(t);
      if (mounted) _snack('Task deleted');
    }
  }

  Future<String?> _askEmail() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send tasks by email'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Recipient (optional)',
            hintText: 'name@example.com',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Open email app')),
        ],
      ),
    );
  }

  Future<void> _onMenu(_Menu m) async {
    final state = AppScope.of(context);
    final tasks = state.allTasks;
    try {
      switch (m) {
        case _Menu.settings:
          await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()));
          return;
        case _Menu.csv:
          if (tasks.isEmpty) return _snack('No tasks to export yet');
          await ExportService.exportCsv(tasks);
          _snack('CSV exported');
        case _Menu.pdf:
          if (tasks.isEmpty) return _snack('No tasks to export yet');
          await ExportService.exportPdf(tasks);
          _snack('PDF exported');
        case _Menu.email:
          if (tasks.isEmpty) return _snack('No tasks to export yet');
          final to = await _askEmail();
          if (to == null) return;
          final ok = await ExportService.sendEmail(tasks, to: to);
          if (!ok) _snack('No email app available on this device');
      }
    } catch (e) {
      _snack('Export failed: $e');
    }
  }

  // ---------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    if (state.error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not start the app:\n${state.error}',
                textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final wide = MediaQuery.of(context).size.width >= 760;

    final destinations = const [
      (Icons.today_outlined, Icons.today, 'Today'),
      (Icons.check_circle_outline, Icons.check_circle, 'Completed'),
      (Icons.repeat, Icons.repeat_on, 'Repeated'),
    ];

    final body = _buildBody(state);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          PopupMenuButton<_Menu>(
            tooltip: 'Menu',
            onSelected: _onMenu,
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: _Menu.csv,
                  child: ListTile(
                      leading: Icon(Icons.table_chart_outlined),
                      title: Text('Export CSV'))),
              PopupMenuItem(
                  value: _Menu.pdf,
                  child: ListTile(
                      leading: Icon(Icons.picture_as_pdf_outlined),
                      title: Text('Export PDF'))),
              PopupMenuItem(
                  value: _Menu.email,
                  child: ListTile(
                      leading: Icon(Icons.email_outlined),
                      title: Text('Send by email'))),
              PopupMenuDivider(),
              PopupMenuItem(
                  value: _Menu.settings,
                  child: ListTile(
                      leading: Icon(Icons.settings_outlined),
                      title: Text('Settings'))),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                      icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3),
              ],
            ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                          icon: Icon(d.$1),
                          selectedIcon: Icon(d.$2),
                          label: Text(d.$3)),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
    );
  }

  Widget _buildBody(AppState state) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<Widget> children = [];

    if (_index == 0) {
      children.add(_todaySummary(state));
    }
    children.add(_categoryChips());

    List<Task> main;
    switch (_index) {
      case 0:
        final overdue = state.overdueTasks(_category);
        main = state.todayTasks(_category);
        if (overdue.isNotEmpty) {
          children.add(_header('Overdue', overdue.length));
          children.addAll(overdue.map(_tile));
        }
        if (main.isNotEmpty) {
          children.add(_header('Due today', main.length));
          children.addAll(main.map(_tile));
        }
        if (overdue.isEmpty && main.isEmpty) {
          children.add(const _Empty(
              icon: Icons.wb_sunny_outlined,
              text: 'Nothing due today.\nTap "Add task" to create one.'));
        }
      case 1:
        main = state.completedTasks(_category);
        children.addAll(main.map(_tile));
        if (main.isEmpty) {
          children.add(const _Empty(
              icon: Icons.task_alt, text: 'No completed tasks yet.'));
        }
      default:
        main = state.repeatedTasks(_category);
        children.addAll(main.map(_tile));
        if (main.isEmpty) {
          children.add(const _Empty(
              icon: Icons.repeat,
              text: 'No repeating tasks.\nSet a repeat when adding a task.'));
        }
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: children,
        ),
      ),
    );
  }

  Widget _tile(Task t) {
    final state = AppScope.of(context);
    return TaskTile(
      key: ValueKey('task_${t.id}'),
      task: t,
      onToggle: () => state.toggleComplete(t),
      onTap: () => _openForm(t),
      onMenu: (a) {
        if (a == TaskMenuAction.edit) {
          _openForm(t);
        } else {
          _confirmDelete(t);
        }
      },
    );
  }

  Widget _header(String title, int count) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
        child: Text('$title  ($count)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                )),
      );

  Widget _todaySummary(AppState state) {
    final done = state.completedTodayCount;
    final left = state.overdueTasks().length + state.todayTasks().length;
    final total = done + left;
    final value = total == 0 ? 0.0 : done / total;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              total == 0 ? 'No tasks for today' : '$done of $total tasks done today',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: value, minHeight: 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChips() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: const Text('All'),
                selected: _category == null,
                onSelected: (_) => setState(() => _category = null),
              ),
            ),
            for (final c in kCategories)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
              ),
          ],
        ),
      );
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Empty({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(icon, size: 56, color: color.withAlpha(150)),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
