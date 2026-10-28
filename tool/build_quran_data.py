"""Membangun assets/quran/quran.json dari sumber terbuka.

Sumber (unduh manual, lihat README.md):
  1. Teks dan tata letak mushaf Madinah 15 baris (KFGQPC Hafs) dari
     quran-ws/quran-text (hafs.json), CC BY 4.0. Teks ini cocok dengan font
     KFGQPC HAFS Uthmanic Script yang ikut dibundel.
  2. Teks Tanzil Uthmani 1.0.2 (quran-uthmani.xml), (c) Tanzil.net, CC BY 3.0,
     hanya dipakai untuk memetakan anotasi tajwid.
  3. Anotasi tajwid cpfair/quran-tajweed
     (tajweed.hafs.uthmani-pause-sajdah.json), CC BY 4.0.

Anotasi cpfair dibuat untuk teks Tanzil, jadi dipetakan ke teks KFGQPC per
huruf: kata ke-n Tanzil dipasangkan dengan kata ke-n KFGQPC, lalu huruf dasar
ke-k dengan huruf dasar ke-k (beserta harakatnya).

Pemakaian:
  python3 tool/build_quran_data.py quran-uthmani.xml tajweed.json hafs.json [keluaran]
"""
import bisect
import json
import sys
import unicodedata
import xml.etree.ElementTree as ET

TANZIL_MARKS = set('ۖۗۚۛۜۙۘ۩۞')
RULES = [
    'hamzat_wasl', 'lam_shamsiyyah', 'silent', 'madd_2', 'madd_246',
    'madd_muttasil', 'madd_munfasil', 'madd_6', 'ghunnah', 'qalqalah',
    'ikhfa', 'ikhfa_shafawi', 'iqlab', 'idghaam_ghunnah',
    'idghaam_no_ghunnah', 'idghaam_shafawi', 'idghaam_mutajanisayn',
    'idghaam_mutaqaribayn',
]
FIRST_CHAR = {
    'hamzat_wasl': 'ٱ', 'lam_shamsiyyah': 'ل', 'ghunnah': 'نم',
    'qalqalah': 'قطبجد', 'madd_2': 'ٰۥۦ', 'silent': 'اويى',
    'ikhfa_shafawi': 'م', 'idghaam_shafawi': 'م',
}


def clusters(word):
    """Pisah kata menjadi rentang [huruf dasar + tanda sesudahnya]."""
    out = []
    for i, ch in enumerate(word):
        base = unicodedata.category(ch) != 'Mn' or ch == 'ٰ'
        if ch == 'ـ':  # tatwil ikut huruf sebelumnya
            base = False
        if base or not out:
            out.append([i, i + 1])
        else:
            out[-1][1] = i + 1
    return out


def map_word_colors(tz_word, tz_rules, qpc_word):
    """Aturan per karakter kata Tanzil -> [[rule, start, end]] di kata QPC."""
    tc, qc = clusters(tz_word), clusters(qpc_word)
    if len(tc) != len(qc):
        return None
    spans = []
    for (ts, te), (qs, qe) in zip(tc, qc):
        rules = [r for r in tz_rules[ts:te] if r is not None]
        if not rules:
            continue
        rule = max(set(rules), key=rules.count)
        if spans and spans[-1][0] == rule and spans[-1][2] == qs:
            spans[-1][2] = qe
        else:
            spans.append([rule, qs, qe])
    return spans


def main(xml_path, tajweed_path, layout_path, out_path):
    # --- Tanzil + tajwid (hanya untuk pemetaan warna) ---
    root = ET.parse(xml_path).getroot()
    tanzil = []
    for s in root.iter('sura'):
        for a in s.iter('aya'):
            tanzil.append((int(s.get('index')), int(a.get('index')),
                           a.get('text'), a.get('bismillah')))
    tj = {(e['surah'], e['ayah']): e['annotations']
          for e in json.load(open(tajweed_path, encoding='utf-8'))}

    # --- KFGQPC: kata, tanda waqaf, tata letak ---
    q = json.load(open(layout_path, encoding='utf-8'))
    words = q['words']
    n_words = len(words)
    starts = q['ayah_starts'] + [n_words]
    line_starts = q['line_starts']
    page_starts = q['page_starts']
    juz_starts = q['juz_starts']
    mark_types = q['mark_types']
    after = {}
    for pos, t in q['marks']:
        mt = mark_types[t]
        # Tanda waqaf dan sajdah ditempel setelah kata; ۞ dan garis sajdah dilewati.
        if mt['side'] == 'after' and mt['kind'] in ('waqf', 'sajdah'):
            after[pos] = after.get(pos, '') + mt['sign']

    lines = []
    for li, ws in enumerate(line_starts):
        p = bisect.bisect_right(page_starts, ws) - 1
        first_line = bisect.bisect_left(line_starts, page_starts[p])
        lines.append([p + 1, li - first_line])

    suras = [[s['name_ar'], s['ayah_count']] for s in q['surahs']]
    # Sumber menulis الشورى dengan ya (ي); di mushaf ditulis alif maqsurah (ى).
    suras[41][0] = suras[41][0].replace('\u0631\u064a', '\u0631\u0649')
    out_ayahs = []
    dropped = mapped_words = unmapped_words = 0
    bismillah = None
    for i, (si, ai, tz_text, tz_bism) in enumerate(tanzil):
        q0, q1 = starts[i], starts[i + 1]
        qwords = [words[k] + after.get(k, '') for k in range(q0, q1)]
        text = ' '.join(qwords)
        if bismillah is None:
            bismillah = text  # Al-Fatihah ayat 1

        # Warna per karakter di teks Tanzil (offset cpfair memuat basmalah di ayat 1).
        prefix = (tz_bism + ' ') if tz_bism else ''
        full = prefix + tz_text
        char_rule = [None] * len(full)
        for an in tj.get((si, ai), []):
            st, en = an['start'], an['end']
            seg = full[st:en]
            want = FIRST_CHAR.get(an['rule'])
            if en > len(full) or not seg or (want and seg[0] not in want):
                dropped += 1
                continue
            for c in range(st, en):
                char_rule[c] = RULES.index(an['rule'])
        char_rule = char_rule[len(prefix):]

        tz_tokens = []
        off = 0
        for t in tz_text.split(' '):
            if not (len(t) == 1 and t in TANZIL_MARKS):
                tz_tokens.append((t, char_rule[off:off + len(t)]))
            off += len(t) + 1

        tajweed = []
        if len(tz_tokens) == len(qwords):
            qoff = 0
            for (tw, tr), qw in zip(tz_tokens, qwords):
                spans = map_word_colors(tw, tr, qw)
                if spans is None:
                    unmapped_words += 1
                else:
                    mapped_words += 1
                    tajweed += [[r, qoff + a, qoff + b] for r, a, b in spans]
                qoff += len(qw) + 1
        else:
            unmapped_words += len(qwords)

        tok_lines = [bisect.bisect_right(line_starts, k) - 1 for k in range(q0, q1)]
        out_ayahs.append([
            text,
            tajweed,
            tok_lines,
            lines[tok_lines[0]][0],
            bisect.bisect_right(juz_starts, q0),
            bismillah if (ai == 1 and si not in (1, 9)) else '',
        ])

    data = {
        'sumber': {
            'teks': 'Teks mushaf Madinah (KFGQPC Hafs) dan tata letak 15 baris '
                    'dari quran-ws/quran-text, CC BY 4.0',
            'tajwid': 'cpfair/quran-tajweed (CC BY 4.0) atas teks Tanzil '
                      'Uthmani 1.0.2 (tanzil.net, CC BY 3.0), dipetakan per huruf',
            'font': 'KFGQPC HAFS Uthmanic Script, King Fahd Glorious Quran '
                    'Printing Complex (fonts.qurancomplex.gov.sa)',
        },
        'rules': RULES,
        'lines': lines,
        'surahs': suras,
        'bismillah': bismillah,
        'ayahs': out_ayahs,
    }
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, separators=(',', ':'))
    total = mapped_words + unmapped_words
    print(f'ayat={len(out_ayahs)} tajwid_dibuang={dropped} '
          f'kata_berwarna={mapped_words}/{total} ({100 * mapped_words / total:.1f}%)')


if __name__ == '__main__':
    main(*sys.argv[1:4], sys.argv[4] if len(sys.argv) > 4 else 'assets/quran/quran.json')
