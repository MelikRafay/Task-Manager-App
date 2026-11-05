import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'state/app_state.dart';

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

  ThemeData _theme(Brightness b) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: b,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      );

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
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          themeMode: state.themeMode,
          home: const HomeScreen(),
        );
      }),
    );
  }
}
