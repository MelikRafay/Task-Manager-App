import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../state/app_state.dart';
import '../utils/constants.dart';
import '../utils/repeat.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task; // null = add, otherwise edit
  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _desc;
  final TextEditingController _subCtrl = TextEditingController();

  late DateTime _due;
  late String _category;
  late RepeatType _repeat;
  late Set<int> _days;
  late List<SubTask> _subs;

  bool get _editing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _desc = TextEditingController(text: t?.description ?? '');
    final soon = DateTime.now().add(const Duration(hours: 1));
    _due = t?.dueDate ??
        DateTime(soon.year, soon.month, soon.day, soon.hour, 0);
    _category = t?.category ?? kCategories.first;
    _repeat = t?.repeatType ?? RepeatType.none;
    _days = {...?t?.repeatDays};
    _subs = [...?t?.subtasks];
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _subCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => _due = DateTime(d.year, d.month, d.day, _due.hour, _due.minute));
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due),
    );
    if (t != null) {
      setState(() => _due = DateTime(_due.year, _due.month, _due.day, t.hour, t.minute));
    }
  }

  void _addSubtask() {
    final text = _subCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subs.add(SubTask(title: text));
      _subCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_repeat == RepeatType.weekly && _days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pick at least one day of the week')));
      return;
    }
    _addSubtask(); // include a half-typed subtask

    var due = _due;
    if (_repeat == RepeatType.weekly) due = alignToRepeat(due, _days);

    final old = widget.task;
    final task = Task(
      id: old?.id,
      title: _title.text.trim(),
      description: _desc.text.trim(),
      dueDate: due,
      isCompleted: old?.isCompleted ?? false,
      completedAt: old?.completedAt,
      repeatType: _repeat,
      repeatDays: _repeat == RepeatType.weekly ? _days : <int>{},
      category: _category,
      subtasks: _subs,
      createdAt: old?.createdAt ?? DateTime.now(),
    );

    final state = AppScope.of(context);
    final nav = Navigator.of(context);
    await state.saveTask(task);
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final done = _subs.where((s) => s.done).length;
    final progress = _subs.isEmpty ? 0.0 : done / _subs.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit task' : 'New task'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Title *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _desc,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 18),

                Text('Due', style: text.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(DateFormat('EEE, d MMM yyyy').format(_due)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(DateFormat('h:mm a').format(_due)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                Text('Category', style: text.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final c in kCategories)
                      ChoiceChip(
                        label: Text(c),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                Text('Repeat', style: text.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<RepeatType>(
                  segments: const [
                    ButtonSegment(value: RepeatType.none, label: Text('Never')),
                    ButtonSegment(value: RepeatType.daily, label: Text('Daily')),
                    ButtonSegment(
                        value: RepeatType.weekly, label: Text('Selected days')),
                  ],
                  selected: {_repeat},
                  onSelectionChanged: (s) => setState(() => _repeat = s.first),
                ),
                if (_repeat == RepeatType.weekly) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (var d = 1; d <= 7; d++)
                        FilterChip(
                          label: Text(kWeekdayShort[d - 1]),
                          selected: _days.contains(d),
                          onSelected: (on) => setState(() {
                            on ? _days.add(d) : _days.remove(d);
                          }),
                        ),
                    ],
                  ),
                ],
                if (_repeat != RepeatType.none)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'When you complete it, the task resets automatically and '
                      'moves to its next occurrence.',
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                const SizedBox(height: 22),

                Row(
                  children: [
                    Text('Subtasks', style: text.titleSmall),
                    const Spacer(),
                    if (_subs.isNotEmpty)
                      Text('$done/${_subs.length}  ·  ${(progress * 100).round()}%',
                          style: text.bodySmall),
                  ],
                ),
                if (_subs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: progress, minHeight: 8),
                  ),
                ],
                const SizedBox(height: 4),
                for (var i = 0; i < _subs.length; i++)
                  ListTile(
                    key: ValueKey('sub_$i${_subs[i].title}'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: _subs[i].done,
                      onChanged: (v) => setState(
                          () => _subs[i] = _subs[i].copyWith(done: v ?? false)),
                    ),
                    title: Text(
                      _subs[i].title,
                      style: TextStyle(
                          decoration:
                              _subs[i].done ? TextDecoration.lineThrough : null),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Remove',
                      onPressed: () => setState(() => _subs.removeAt(i)),
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subCtrl,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Add a subtask',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addSubtask(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addSubtask,
                      icon: const Icon(Icons.add),
                      tooltip: 'Add subtask',
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
