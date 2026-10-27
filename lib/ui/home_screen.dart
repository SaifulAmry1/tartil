import 'package:flutter/material.dart';

import '../services/store.dart';
import '../teks.dart';
import 'dashboard_page.dart';
import 'mushaf_index_page.dart';
import 'plan_screen.dart';
import 'profile_form.dart';
import 'profile_page.dart';
import 'record_screen.dart';
import 'theme.dart';
import 'widgets.dart';

/// Kerangka utama: navigasi bawah dengan tombol Murojaah di tengah dan
/// profil di kanan bawah.
class HomeScreen extends StatefulWidget {
  final AppState app;
  const HomeScreen({super.key, required this.app});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  AppState get app => widget.app;
  int _tab = 0;

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

  void _murojaah() {
    final p = app.active!;
    final c = p.cycle!;
    final day = c.days[c.indexOf(DateTime.now()).clamp(0, c.length - 1)];
    final u = day.units.isEmpty ? null : day.units.first;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => u == null
          ? RecordScreen(app: app)
          : RecordScreen(app: app, profile: p, surah: u.surah, fromAyah: u.fromAyah, toAyah: u.toAyah),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final p = app.active;
        if (p == null) return _Welcome(app: app);
        final pages = [
          DashboardPage(app: app, profile: p, onOpenSchedule: () => setState(() => _tab = 1)),
          SchedulePage(app: app, profile: p),
          MushafIndexPage(quran: app.quran),
          ProfilePage(app: app),
        ];
        return Scaffold(
          extendBody: true,
          body: IndexedStack(index: _tab, children: pages),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: SizedBox(
            width: 64,
            height: 64,
            child: FloatingActionButton(
              heroTag: 'murojaah',
              backgroundColor: TartilColors.emas,
              foregroundColor: Colors.white,
              elevation: 0,
              highlightElevation: 0,
              shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 3)),
              tooltip: Teks.navMurojaah,
              onPressed: _murojaah,
              child: const Icon(Icons.mic_rounded, size: 30),
            ),
          ),
          bottomNavigationBar: BottomAppBar(
            color: Colors.white,
            elevation: 12,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            height: 72,
            padding: EdgeInsets.zero,
            child: Row(children: [
              _item(0, Icons.home_outlined, Icons.home_rounded, Teks.navBeranda),
              _item(1, Icons.calendar_month_outlined, Icons.calendar_month, Teks.navJadwal),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text(Teks.navMurojaah,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: TartilColors.emas)),
                ),
              ),
              _item(2, Icons.menu_book_outlined, Icons.menu_book, Teks.navMushaf),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _tab = 3),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _tab == 3 ? TartilColors.hijau : Colors.transparent, width: 2),
                      ),
                      child: ProfileAvatar(profile: p, radius: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: _tab == 3 ? FontWeight.w700 : FontWeight.w500,
                          color: _tab == 3 ? TartilColors.hijau : Colors.black54,
                        )),
                  ]),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _item(int i, IconData icon, IconData active, String label) {
    final on = _tab == i;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = i),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(on ? active : icon, color: on ? TartilColors.hijau : Colors.black45),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                color: on ? TartilColors.hijau : Colors.black54,
              )),
        ]),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  final AppState app;
  const _Welcome({required this.app});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: HeaderBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(children: [
                const Spacer(),
                const Rub(size: 120, color: TartilColors.emas),
                const SizedBox(height: 24),
                const Text(Teks.selamatDatang,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text(Teks.kepanjangan,
                    textAlign: TextAlign.center, style: TextStyle(color: TartilColors.emas, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                const Text(Teks.selamatDatangKet,
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, height: 1.5)),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: TartilColors.emas,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileForm(app: app))),
                  child: const Text(Teks.buatProfil, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ),
        ),
      );
}
