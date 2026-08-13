import 'package:flutter/material.dart';

import 'navigation/main_navigation.dart';

void main() {
  runApp(const TraceLockedApp());
}

class TraceLockedApp extends StatefulWidget {
  const TraceLockedApp({super.key});

  @override
  State<TraceLockedApp> createState() => _TraceLockedAppState();
}

class _TraceLockedAppState extends State<TraceLockedApp> {
  ThemeMode themeMode = ThemeMode.light;

  void toggleDarkMode(bool enabled) {
    setState(() {
      themeMode = enabled
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TraceLocked',

      themeMode: themeMode,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),

      home: MainNavigation(
        darkModeEnabled:
            themeMode == ThemeMode.dark,
        onDarkModeChanged: toggleDarkMode,
      ),
    );
  }
}