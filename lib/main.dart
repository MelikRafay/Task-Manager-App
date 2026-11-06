import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.init();
  runApp(TaskApp(state: state));
}

class TaskApp extends StatefulWidget {
  final AppState state;
  const TaskApp({super.key, required this.state});

  @override
  State<TaskApp> createState() => _TaskAppState();
}

class _TaskAppState extends State<TaskApp> {
  @override
  void initState() {
    super.initState();
    widget.state.onReminder = (task) {
      messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          duration: const Duration(seconds: 10),
          content: Text('Task due: ${task.title}'),
          action: SnackBarAction(
            label: 'Done',
            onPressed: () => widget.state.toggleComplete(task),
          ),
        ));
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: Builder(builder: (context) {
        final state = AppScope.of(context);
        return MaterialApp(
          title: 'Task Manager',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: messengerKey,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: state.themeMode,
          home: const _Gate(),
        );
      }),
    );
  }
}

/// Shows the welcome screen on first launch, then the home screen.
class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  bool? _seen;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var seen = true; // if storage fails, don't block the user
    try {
      final p = await SharedPreferences.getInstance();
      seen = p.getBool('seen_welcome') ?? false;
    } catch (_) {}
    if (mounted) setState(() => _seen = seen);
  }

  Future<void> _continue() async {
    final state = AppScope.of(context);
    try {
      final p = await SharedPreferences.getInstance();
      final hadTheme = p.containsKey('theme');
      await p.setBool('seen_welcome', true);
      // New look defaults to dark unless the user already chose a theme.
      if (!hadTheme) await state.setThemeMode(ThemeMode.dark);
    } catch (_) {}
    if (mounted) setState(() => _seen = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_seen == null) return const Scaffold();
    if (_seen == false) return WelcomeScreen(onContinue: _continue);
    return const HomeScreen();
  }
}
