import 'package:flutter/material.dart';

import 'features/player/presentation/pages/player_page.dart';

class RhemaDailyApp extends StatelessWidget {
  const RhemaDailyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rhema Daily',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      home: const PlayerPage(),
    );
  }
}