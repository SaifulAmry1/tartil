import 'package:flutter/material.dart';

import '../services/store.dart';
import '../teks.dart';
import 'about_screen.dart';
import 'plan_screen.dart';
import 'profile_form.dart';
import 'reader_screen.dart';
import 'record_screen.dart';
import 'theme.dart';

class HomeScreen extends StatefulWidget {
  final AppState app;
  const HomeScreen({super.key, required this.app});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  AppState get app => widget.app;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Aplikasi dibuka lagi (mungkin di hari lain): sesuaikan jadwal.
    if (state == AppLifecycleState.resumed) app.refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Rub(size: 28),
          SizedBox(width: 10),
          Text(Teks.appName, style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        ]),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => Navigator.push(context, MaterialPageRoute(builder: (_) {
              switch (v) {
                case 'mushaf':
                  return ReaderScreen(quran: app.quran, startPage: 1);
                case 'uji':
                  return RecordScreen(app: app);
                default:
                  return AboutScreen(quran: app.quran);
              }
            })),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'mushaf', child: Text(Teks.bacaMushaf)),
              PopupMenuItem(value: 'uji', child: Text(Teks.ujiSuara)),
              PopupMenuItem(value: 'tentang', child: Text(Teks.tentang)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: TartilColors.emas,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileForm(app: app))),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text(Teks.tambahProfil),
      ),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          if (app.profiles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Rub(size: 96),
                  const SizedBox(height: 16),
                  const Text(Teks.kepanjangan, style: TextStyle(color: TartilColors.hijau, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  const Text(Teks.profilKosong, textAlign: TextAlign.center),
                ]),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            children: [
              for (final p in app.profiles)
                Builder(builder: (context) {
                  final c = p.cycle!;
                  final i = c.indexOf(DateTime.now()).clamp(0, c.length - 1);
                  final day = c.days[i];
                  final names = day.units.map((u) => app.quran.surah(u.surah).name).toSet().join(', ');
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => PlanScreen(app: app, profile: p))),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: TartilColors.hijauMuda,
                            child: Text(p.name.characters.first.toUpperCase(),
                                style: const TextStyle(fontSize: 22, color: TartilColors.hijau)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(Teks.hariKe(i + 1, c.length)),
                              const SizedBox(height: 4),
                              Text(names.isEmpty ? Teks.libur : names,
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.black54)),
                            ]),
                          ),
                          Icon(day.done ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: day.done ? TartilColors.hijau : TartilColors.emas, size: 30),
                        ]),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
