// Algoritma jadwal murojaah: membagi rentang hafalan ke N hari dengan
// durasi harian seimbang. Murni Dart, tanpa Flutter, agar mudah diuji.

/// Bagian bacaan: satu surah utuh atau potongan ayat dari surah panjang.
class Unit {
  final int surah;
  final int fromAyah;
  final int toAyah;
  final double seconds;

  /// Total ayat surah, untuk menentukan apakah unit ini surah utuh.
  final int surahAyahs;

  /// true jika unit ini tambahan pengulangan untuk surah lemah.
  final bool review;

  const Unit({
    required this.surah,
    required this.fromAyah,
    required this.toAyah,
    required this.seconds,
    required this.surahAyahs,
    this.review = false,
  });

  bool get isWhole => fromAyah == 1 && toAyah == surahAyahs;

  String get key => '$surah:$fromAyah-$toAyah${review ? 'u' : ''}';

  /// Urutan mushaf, untuk mengurutkan bacaan dalam satu hari.
  int get order => surah * 1000 + fromAyah;

  Unit copyWith({bool? review}) => Unit(
        surah: surah,
        fromAyah: fromAyah,
        toAyah: toAyah,
        seconds: seconds,
        surahAyahs: surahAyahs,
        review: review ?? this.review,
      );

  Map<String, dynamic> toJson() => {
        's': surah,
        'f': fromAyah,
        't': toAyah,
        'd': seconds,
        'n': surahAyahs,
        if (review) 'u': true,
      };

  factory Unit.fromJson(Map<String, dynamic> j) => Unit(
        surah: j['s'] as int,
        fromAyah: j['f'] as int,
        toAyah: j['t'] as int,
        seconds: (j['d'] as num).toDouble(),
        surahAyahs: j['n'] as int,
        review: j['u'] == true,
      );

  @override
  String toString() => key;
}

/// Durasi per ayat dari satu surah (atau sebagian surah bila rentang juz
/// memotong surah), dipakai untuk memotong surah panjang.
class SurahDurations {
  final int surah;
  final List<double> ayahSeconds;

  /// Nomor ayat pertama dalam [ayahSeconds].
  final int firstAyah;

  /// Jumlah ayat surah seutuhnya.
  final int surahAyahs;

  SurahDurations(this.surah, this.ayahSeconds, {this.firstAyah = 1, int? surahAyahs})
      : surahAyahs = surahAyahs ?? firstAyah - 1 + ayahSeconds.length;

  int get lastAyah => firstAyah + ayahSeconds.length - 1;

  double get total => ayahSeconds.fold(0.0, (a, b) => a + b);

  Unit whole() => slice(firstAyah, lastAyah);

  /// Unit dari ayat [from] sampai [to] (nomor ayat sebenarnya).
  Unit slice(int from, int to) {
    var s = 0.0;
    for (var a = from; a <= to; a++) {
      s += ayahSeconds[a - firstAyah];
    }
    return Unit(
      surah: surah,
      fromAyah: from,
      toAyah: to,
      seconds: s,
      surahAyahs: surahAyahs,
    );
  }

  /// Potong menjadi [k] bagian berurutan dengan durasi semirip mungkin.
  List<Unit> split(int k) {
    final n = ayahSeconds.length;
    if (k <= 1 || n <= 1) return [whole()];
    k = k > n ? n : k;
    final total = this.total;
    final parts = <Unit>[];
    var start = 0;
    var acc = 0.0;
    for (var part = 1; part < k; part++) {
      final goal = total * part / k;
      var end = start;
      acc += ayahSeconds[end];
      // Lanjutkan selama ayat berikutnya membawa total lebih dekat ke sasaran
      // dan masih tersisa cukup ayat untuk bagian-bagian berikutnya.
      while (end + 1 <= n - 1 - (k - part) &&
          (acc + ayahSeconds[end + 1] - goal).abs() <= (acc - goal).abs()) {
        end++;
        acc += ayahSeconds[end];
      }
      parts.add(slice(firstAyah + start, firstAyah + end));
      start = end + 1;
    }
    parts.add(slice(firstAyah + start, lastAyah));
    return parts;
  }
}

/// Batas toleransi: surah dipotong hanya jika lebih panjang dari
/// target harian dikali faktor ini.
const double splitTolerance = 1.15;

/// Bagi daftar surah dalam rentang menjadi [days] hari.
///
/// Surah dibiarkan utuh sebisa mungkin. Surah dipotong hanya jika
/// durasinya jauh melebihi target harian, atau jika jumlah surah lebih
/// sedikit dari jumlah hari.
List<List<Unit>> planCycle(List<SurahDurations> surahs, int days) {
  if (days < 1) throw ArgumentError('Jumlah hari minimal 1');
  if (surahs.isEmpty) return List.generate(days, (_) => <Unit>[]);
  final total = surahs.fold(0.0, (a, s) => a + s.total);
  final target = total / days;
  final byNo = {for (final s in surahs) s.surah: s};

  // Jumlah potongan per surah.
  final pieces = <int, int>{};
  for (final s in surahs) {
    final k = s.total > target * splitTolerance ? (s.total / target).ceil() : 1;
    pieces[s.surah] = k.clamp(1, s.ayahSeconds.length);
  }
  List<Unit> buildUnits() => [
        for (final s in surahs) ...s.split(pieces[s.surah]!),
      ];
  var units = buildUnits();
  // Jika unit lebih sedikit dari hari, potong unit terpanjang yang masih bisa.
  while (units.length < days) {
    Unit? longest;
    for (final u in units) {
      final canSplit = pieces[u.surah]! < byNo[u.surah]!.ayahSeconds.length;
      if (canSplit && (longest == null || u.seconds > longest.seconds)) {
        longest = u;
      }
    }
    if (longest == null) break;
    pieces[longest.surah] = pieces[longest.surah]! + 1;
    units = buildUnits();
  }
  return balance(units, days);
}

/// Bagi unit ke [days] hari agar total per hari seimbang (LPT lalu
/// perbaikan lokal dengan pindah dan tukar).
List<List<Unit>> balance(List<Unit> units, int days) {
  final bins = List.generate(days, (_) => <Unit>[]);
  final load = List.filled(days, 0.0);
  final sorted = [...units]..sort((a, b) {
      final c = b.seconds.compareTo(a.seconds);
      return c != 0 ? c : a.order.compareTo(b.order);
    });
  for (final u in sorted) {
    var best = 0;
    for (var d = 1; d < days; d++) {
      if (load[d] < load[best]) best = d;
    }
    bins[best].add(u);
    load[best] += u.seconds;
  }
  _improve(bins, load);
  for (final b in bins) {
    b.sort((x, y) => x.order.compareTo(y.order));
  }
  // Urutkan hari mengikuti urutan mushaf bacaan pertamanya; hari kosong di akhir.
  bins.sort((a, b) {
    if (a.isEmpty || b.isEmpty) return a.isEmpty ? (b.isEmpty ? 0 : 1) : -1;
    return a.first.order.compareTo(b.first.order);
  });
  _orderSplitParts(bins);
  return bins;
}

double _spread(List<double> load) {
  // Jumlah kuadrat: turun jika beban makin rata.
  var s = 0.0;
  for (final l in load) {
    s += l * l;
  }
  return s;
}

void _improve(List<List<Unit>> bins, List<double> load) {
  final days = bins.length;
  for (var iter = 0; iter < 2000; iter++) {
    var improved = false;
    final before = _spread(load);
    outer:
    for (var a = 0; a < days; a++) {
      for (var b = 0; b < days; b++) {
        if (a == b || load[a] <= load[b]) continue;
        // Pindah satu unit dari a ke b.
        for (var i = 0; i < bins[a].length; i++) {
          final u = bins[a][i];
          if (bins[a].length == 1 && bins[b].isNotEmpty) continue;
          final na = load[a] - u.seconds, nb = load[b] + u.seconds;
          if (na * na + nb * nb < load[a] * load[a] + load[b] * load[b] - 1e-6) {
            bins[a].removeAt(i);
            bins[b].add(u);
            load[a] = na;
            load[b] = nb;
            improved = true;
            break outer;
          }
        }
        // Tukar satu unit a dengan satu unit b.
        for (var i = 0; i < bins[a].length; i++) {
          for (var j = 0; j < bins[b].length; j++) {
            final ua = bins[a][i], ub = bins[b][j];
            final delta = ua.seconds - ub.seconds;
            if (delta <= 0) continue;
            final na = load[a] - delta, nb = load[b] + delta;
            if (na * na + nb * nb < load[a] * load[a] + load[b] * load[b] - 1e-6) {
              bins[a][i] = ub;
              bins[b][j] = ua;
              load[a] = na;
              load[b] = nb;
              improved = true;
              break outer;
            }
          }
        }
      }
    }
    if (!improved || _spread(load) >= before) break;
  }
}

/// Pastikan potongan surah yang sama dibaca berurutan: potongan awal
/// ditempatkan di hari lebih awal. Durasi potongan hampir sama, jadi
/// menukar posisinya hanya sedikit mengubah keseimbangan.
void _orderSplitParts(List<List<Unit>> bins) {
  final parts = <int, List<(int day, int idx)>>{};
  for (var d = 0; d < bins.length; d++) {
    for (var i = 0; i < bins[d].length; i++) {
      final u = bins[d][i];
      if (!u.isWhole && !u.review) {
        parts.putIfAbsent(u.surah, () => []).add((d, i));
      }
    }
  }
  for (final slots in parts.values) {
    if (slots.length < 2) continue;
    final units = [for (final (d, i) in slots) bins[d][i]]
      ..sort((a, b) => a.fromAyah.compareTo(b.fromAyah));
    final ordered = [...slots]..sort((a, b) {
        final c = a.$1.compareTo(b.$1);
        return c != 0 ? c : a.$2.compareTo(b.$2);
      });
    for (var k = 0; k < ordered.length; k++) {
      bins[ordered[k].$1][ordered[k].$2] = units[k];
    }
  }
  for (final b in bins) {
    b.sort((x, y) => x.order.compareTo(y.order));
  }
}

/// Tambahkan pengulangan surah lemah ke hari teringan yang belum memuat
/// surah tersebut. [fromDay] membatasi hari yang boleh diisi.
void addReviews(List<List<Unit>> plan, Iterable<Unit> weak, {int fromDay = 0}) {
  for (final w in weak) {
    int? best;
    double bestLoad = double.infinity;
    for (var d = fromDay; d < plan.length; d++) {
      if (plan[d].any((u) => u.surah == w.surah)) continue;
      final l = plan[d].fold(0.0, (a, u) => a + u.seconds);
      if (l < bestLoad) {
        bestLoad = l;
        best = d;
      }
    }
    if (best != null) {
      plan[best].add(w.copyWith(review: true));
      plan[best].sort((x, y) => x.order.compareTo(y.order));
    }
  }
}

double dayLoad(List<Unit> day) => day.fold(0.0, (a, u) => a + u.seconds);
