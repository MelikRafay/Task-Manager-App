import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../services/export_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/progress_rings.dart';
import '../widgets/task_tile.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'task_form_screen.dart';

enum _Menu { csv, pdf, email, settings }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0; // 0 Today, 1 Completed, 2 Repeated
  String? _category; // filter set by tapping a category card

  static const _tabs = ['Today', 'Completed', 'Repeated'];

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
          TextButton(
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
          TextButton(
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
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
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

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _header(),
                      Expanded(child: _content(state)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          PopupMenuButton<_Menu>(
            tooltip: 'Menu',
            icon: const Icon(Icons.apps_rounded),
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
          Expanded(
            child: Center(
              child: Text(
                DateFormat('EEEE, d').format(DateTime.now()),
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Calendar',
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const CalendarScreen())),
          ),
        ],
      ),
    );
  }

  Widget _content(AppState state) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    List<Task> tasks;
    switch (_tab) {
      case 0:
        tasks = [...state.overdueTasks(_category), ...state.todayTasks(_category)];
      case 1:
        tasks = state.completedTasks(_category);
      default:
        tasks = state.repeatedTasks(_category);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        _tabBar(),
        const SizedBox(height: 14),
        if (_tab == 0) ...[
          _ringsCard(state),
          const SizedBox(height: 22),
        ],
        ..._categorySection(state),
        Row(
          children: [
            Text(_tab == 0 ? 'Tasks' : _tabs[_tab],
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Text('${tasks.length}',
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            const Spacer(),
            if (_category != null)
              InputChip(
                label: Text(_category!),
                onDeleted: () => setState(() => _category = null),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (tasks.isEmpty)
          _empty()
        else
          for (final t in tasks)
            TaskTile(
              key: ValueKey('task_${t.id}'),
              task: t,
              onToggle: () => state.toggleComplete(t),
              onTap: () => _openForm(t),
              onMenu: (a) =>
                  a == TaskMenuAction.edit ? _openForm(t) : _confirmDelete(t),
            ),
      ],
    );
  }

  Widget _tabBar() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _tab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: _tab == i ? AppColors.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _tabs[i],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _tab == i ? Colors.white : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// (category, total tasks, completed tasks)
  List<(String, int, int)> _stats(AppState state) {
    final all = state.allTasks;
    final list = <(String, int, int)>[];
    for (final c in kCategories) {
      final inCat = all.where((t) => t.category == c);
      final total = inCat.length;
      if (total == 0) continue;
      list.add((c, total, inCat.where((t) => t.isCompleted).length));
    }
    list.sort((a, b) => b.$2.compareTo(a.$2));
    return list;
  }

  Widget _ringsCard(AppState state) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final stats = _stats(state).take(3).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: stats.isEmpty
          ? Row(
              children: [
                const Icon(Icons.donut_large, color: AppColors.blue, size: 34),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('Add a task to see your progress here.',
                      style: text.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ),
              ],
            )
          : Row(
              children: [
                ProgressRings(
                  size: 124,
                  values: [for (final s in stats) s.$3 / s.$2],
                  colors: [for (final s in stats) AppColors.category(s.$1)],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      for (final s in stats)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: AppColors.category(s.$1),
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(s.$1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.bodyMedium),
                              ),
                              Text('${(s.$3 / s.$2 * 100).round()}%',
                                  style: text.bodySmall
                                      ?.copyWith(color: scheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _categorySection(AppState state) {
    final text = Theme.of(context).textTheme;
    final stats = _stats(state);
    final cards = <Widget>[];
    for (final s in stats) {
      final pending = state.allTasks
          .where((t) => t.category == s.$1 && !t.isCompleted)
          .toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      if (pending.isEmpty) continue;
      cards.add(_CategoryCard(
        category: s.$1,
        next: pending.first,
        progress: s.$3 / s.$2,
        selected: _category == s.$1,
        onTap: () => setState(() => _category = _category == s.$1 ? null : s.$1),
      ));
    }
    if (cards.isEmpty) return const [];
    return [
      Text('Categories',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      SizedBox(
        height: 152,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: cards,
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  Widget _empty() {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final icons = [Icons.wb_sunny_outlined, Icons.task_alt, Icons.repeat];
    final msgs = [
      'Nothing due today.\nTap + to add a task.',
      'No completed tasks yet.',
      'No repeating tasks.\nSet a repeat when adding a task.',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icons[_tab], size: 54, color: color.withAlpha(140)),
          const SizedBox(height: 12),
          Text(msgs[_tab],
              textAlign: TextAlign.center, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final Task next;
  final double progress;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.next,
    required this.progress,
    required this.selected,
    required this.onTap,
  });

  String _chip() {
    if (next.dueDate.isBefore(DateTime.now())) {
      final l = dayLabel(next.dueDate);
      return l == 'Today' ? 'OVERDUE' : l.toUpperCase();
    }
    return dayLabel(next.dueDate).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = AppColors.category(category);
    final isLate = next.dueDate.isBefore(DateTime.now());
    final chipColor = isLate ? scheme.error : color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 158,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.blue : Colors.transparent, width: 1.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgressRings(
                size: 28, values: [progress], colors: [color], stroke: 5),
            const SizedBox(height: 10),
            Text(category.toUpperCase(),
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
            const SizedBox(height: 3),
            Expanded(
              child: Text(
                next.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600, height: 1.25),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: chipColor.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _chip(),
                style: TextStyle(
                    color: chipColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
