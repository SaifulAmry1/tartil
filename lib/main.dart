import 'package:flutter/foundation.dart';
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
      // Pratinjau web di laptop: tampilkan selebar layar HP di tengah.
      builder: kIsWeb ? _phoneFrame : null,
    );
  }
}

Widget _phoneFrame(BuildContext context, Widget? child) {
  final mq = MediaQuery.of(context);
  final width = mq.size.width.clamp(0.0, 430.0);
  return ColoredBox(
    color: const Color(0xFF0B3D31),
    child: Center(
      child: SizedBox(
        width: width,
        child: MediaQuery(
          data: mq.copyWith(size: Size(width, mq.size.height)),
          child: ClipRect(child: child),
        ),
      ),
    ),
  );
}
