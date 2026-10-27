import 'package:flutter/material.dart';

import 'services/notifications.dart';
import 'services/store.dart';
import 'teks.dart';
import 'ui/home_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = await AppState.load();
  await Notifications.rescheduleAll(app.profiles);
  runApp(TartilApp(app: app));
}

class TartilApp extends StatelessWidget {
  final AppState app;
  const TartilApp({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Teks.appName,
      debugShowCheckedModeBanner: false,
      theme: tartilTheme(),
      home: HomeScreen(app: app),
    );
  }
}
