// Ringkasan kemajuan satu siklus untuk dasbor.
import 'cycle.dart';

class CycleStats {
  final int today;
  final int done;
  final int missed;
  final int streak;

  const CycleStats(this.today, this.done, this.missed, this.streak);

  factory CycleStats.of(Cycle c, DateTime now) {
    final today = c.indexOf(now).clamp(0, c.length - 1);
    final done = c.days.where((d) => d.done).length;
    final missed = c.days.where((d) => d.missed).length;
    // Hari beruntun: hitung mundur dari hari ini (atau kemarin bila hari ini
    // belum selesai) selama hari-harinya selesai.
    var streak = 0;
    var i = c.days[today].done ? today : today - 1;
    while (i >= 0 && c.days[i].done) {
      streak++;
      i--;
    }
    return CycleStats(today, done, missed, streak);
  }
}
