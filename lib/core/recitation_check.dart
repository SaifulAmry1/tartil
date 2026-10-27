// Membandingkan hasil speech-to-text dengan teks ayat yang seharusnya:
// menemukan kata yang salah, terlewat, atau tambahan.

/// Kerangka huruf: tanpa harakat, tanda waqaf, alif, dan hamzah, agar
/// tulisan Utsmani dan tulisan imla'i dari speech-to-text bisa dibandingkan.
String skeleton(String word) {
  final b = StringBuffer();
  for (final r in word.runes) {
    final c = String.fromCharCode(r);
    // Harakat, tanwin, syaddah, sukun, tanda kecil Qur'ani, tatwil.
    if ((r >= 0x0610 && r <= 0x061A) ||
        (r >= 0x064B && r <= 0x065F) ||
        r == 0x0670 ||
        (r >= 0x06D6 && r <= 0x06ED) ||
        (r >= 0x08D3 && r <= 0x08FF) ||
        r == 0x0640) {
      continue;
    }
    switch (c) {
      case 'ا' || 'أ' || 'إ' || 'آ' || 'ٱ' || 'ء' || 'ٲ' || 'ٳ':
        continue;
      case 'ى' || 'ی' || 'ئ':
        b.write('ي');
      case 'ؤ':
        b.write('و');
      case 'ة':
        b.write('ه');
      default:
        if (r >= 0x0621 && r <= 0x064A) b.write(c);
    }
  }
  return b.toString();
}

int _lev(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost]
          .reduce((x, y) => x < y ? x : y);
    }
    prev = cur;
  }
  return prev[b.length];
}

/// Kemiripan dua kata 0..1 berdasarkan kerangka hurufnya.
double wordSimilarity(String expected, String heard) {
  final a = skeleton(expected), b = skeleton(heard);
  if (a.isEmpty && b.isEmpty) return 1;
  final m = a.length > b.length ? a.length : b.length;
  return 1 - _lev(a, b) / m;
}

/// Ambang kata dianggap benar.
const double matchThreshold = 0.7;

enum WordStatus { benar, salah, terlewat }

class WordResult {
  final int index;
  final String expected;
  final WordStatus status;

  /// Kata yang terdengar (untuk status salah).
  final String? heard;

  const WordResult(this.index, this.expected, this.status, [this.heard]);
}

class CheckResult {
  final List<WordResult> words;

  /// Kata tambahan yang tidak ada di teks.
  final List<String> extra;

  const CheckResult(this.words, this.extra);

  int get correct => words.where((w) => w.status == WordStatus.benar).length;

  /// Nilai kelancaran 0..100.
  int get score => words.isEmpty ? 0 : (correct * 100 / words.length).round();
}

/// Pisahkan teks menjadi kata (tanpa token tanda waqaf).
List<String> splitWords(String text) => text
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty && skeleton(w).isNotEmpty)
    .toList();

/// Selaraskan kata harapan dengan kata terdengar (Needleman-Wunsch).
CheckResult compareRecitation(List<String> expected, List<String> heard) {
  final n = expected.length, m = heard.length;
  final sk = [for (final w in expected) skeleton(w)];
  final hk = [for (final w in heard) skeleton(w)];
  double sub(int i, int j) {
    final a = sk[i], b = hk[j];
    final mx = a.length > b.length ? a.length : b.length;
    final sim = mx == 0 ? 1.0 : 1 - _lev(a, b) / mx;
    return sim >= matchThreshold ? 1 - sim : 1.2;
  }

  const gap = 1.0;
  final cost = List.generate(n + 1, (_) => List<double>.filled(m + 1, 0));
  for (var i = 1; i <= n; i++) {
    cost[i][0] = i * gap;
  }
  for (var j = 1; j <= m; j++) {
    cost[0][j] = j * gap;
  }
  for (var i = 1; i <= n; i++) {
    for (var j = 1; j <= m; j++) {
      final d = cost[i - 1][j - 1] + sub(i - 1, j - 1);
      final del = cost[i - 1][j] + gap;
      final ins = cost[i][j - 1] + gap;
      cost[i][j] = d < del ? (d < ins ? d : ins) : (del < ins ? del : ins);
    }
  }
  final words = <WordResult>[];
  final extra = <String>[];
  var i = n, j = m;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && cost[i][j] == cost[i - 1][j - 1] + sub(i - 1, j - 1)) {
      final ok = sub(i - 1, j - 1) < 1;
      words.add(WordResult(i - 1, expected[i - 1],
          ok ? WordStatus.benar : WordStatus.salah, ok ? null : heard[j - 1]));
      i--;
      j--;
    } else if (i > 0 && cost[i][j] == cost[i - 1][j] + gap) {
      words.add(WordResult(i - 1, expected[i - 1], WordStatus.terlewat));
      i--;
    } else {
      extra.add(heard[j - 1]);
      j--;
    }
  }
  return CheckResult(words.reversed.toList(), extra.reversed.toList());
}
