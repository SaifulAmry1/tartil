"""Membangun assets/quran/quran.json dari sumber terbuka.

Sumber (unduh manual, lihat tool/README.md):
  1. Teks Tanzil Uthmani 1.0.2 (quran-uthmani.xml), (c) Tanzil.net, CC BY 3.0,
     disalin apa adanya (verbatim).
  2. Anotasi tajwid cpfair/quran-tajweed
     (tajweed.hafs.uthmani-pause-sajdah.json), CC BY 4.0.
  3. Tata letak halaman/baris mushaf Madinah 15 baris dari quran-ws/quran-text
     (hafs.json), CC BY 4.0.

Pemakaian:
  python3 tool/build_quran_data.py quran-uthmani.xml tajweed.json hafs.json
"""
import bisect
import json
import sys
import xml.etree.ElementTree as ET

MARKS = set('ۖۗۚۛۜۙۘ۩۞')
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


def main(xml_path, tajweed_path, layout_path, out_path):
    root = ET.parse(xml_path).getroot()
    suras = []
    ayahs = []
    for s in root.iter('sura'):
        si = int(s.get('index'))
        suras.append({'n': si, 'ar': s.get('name'), 'c': 0})
        for a in s.iter('aya'):
            ayahs.append({'s': si, 'a': int(a.get('index')),
                          't': a.get('text'), 'b': a.get('bismillah')})
            suras[-1]['c'] += 1

    # Tajwid: offset cpfair dihitung atas "bismillah + spasi + teks" untuk ayat 1.
    tj = {(e['surah'], e['ayah']): e['annotations']
          for e in json.load(open(tajweed_path, encoding='utf-8'))}
    dropped = 0
    for ay in ayahs:
        prefix = (ay['b'] + ' ') if ay['b'] else ''
        full = prefix + ay['t']
        out = []
        for an in tj.get((ay['s'], ay['a']), []):
            st, en = an['start'], an['end']
            seg = full[st:en]
            want = FIRST_CHAR.get(an['rule'])
            if en > len(full) or not seg or (want and seg[0] not in want):
                dropped += 1
                continue
            st -= len(prefix)
            en -= len(prefix)
            if en <= 0:
                continue
            out.append([RULES.index(an['rule']), max(st, 0), en])
        ay['j'] = out

    # Tata letak: petakan kata Tanzil ke kata QPC per ayat untuk nomor baris.
    q = json.load(open(layout_path, encoding='utf-8'))
    n_words = len(q['words'])
    starts = q['ayah_starts'] + [n_words]
    line_starts = q['line_starts']
    page_starts = q['page_starts']
    juz_starts = q['juz_starts']
    # baris global -> (halaman, baris ke-n di halaman)
    lines = []
    for li, ws in enumerate(line_starts):
        p = bisect.bisect_right(page_starts, ws) - 1
        first_line = bisect.bisect_left(line_starts, page_starts[p])
        lines.append([p + 1, li - first_line])
    mismatch = 0
    for i, ay in enumerate(ayahs):
        toks = ay['t'].split(' ')
        q0, q1 = starts[i], starts[i + 1]
        nq = q1 - q0
        nt = sum(1 for t in toks if not (len(t) == 1 and t in MARKS))
        if nt != nq:
            mismatch += 1
        ln = []
        wi = -1
        for t in toks:
            if not (len(t) == 1 and t in MARKS):
                wi += 1
            qi = q0 + min(max(wi, 0), nq - 1)
            ln.append(bisect.bisect_right(line_starts, qi) - 1)
        ay['l'] = ln
        ay['z'] = bisect.bisect_right(juz_starts, q0)
        ay['p'] = lines[ln[0]][0]

    data = {
        'sumber': {
            'teks': 'Tanzil Quran Text (Uthmani, version 1.0.2), (C) 2008-2010 '
                    'Tanzil.net, CC BY 3.0, https://tanzil.net. '
                    'Teks disalin apa adanya; perubahan tidak diizinkan.',
            'tajwid': 'cpfair/quran-tajweed, CC BY 4.0',
            'tata_letak': 'quran-ws/quran-text (Hafs, Madinah 15 baris), CC BY 4.0',
        },
        'rules': RULES,
        'lines': lines,
        'surahs': [[s['ar'], s['c']] for s in suras],
        'bismillah': ayahs[0]['t'],
        'ayahs': [[ay['t'], ay['j'], ay['l'], ay['p'], ay['z'], ay['b'] or '']
                  for ay in ayahs],
    }
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, separators=(',', ':'))
    print(f'ayat={len(ayahs)} tajwid_dibuang={dropped} '
          f'ayat_kata_tak_sama={mismatch} baris={len(lines)}')


if __name__ == '__main__':
    main(*sys.argv[1:4], sys.argv[4] if len(sys.argv) > 4 else 'assets/quran/quran.json')
