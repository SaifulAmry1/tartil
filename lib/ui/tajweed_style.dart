import 'package:flutter/material.dart';

/// Warna dan nama Indonesia untuk tiap aturan tajwid (kunci = nama aturan
/// di data cpfair/quran-tajweed).
class TajweedStyle {
  final Color color;
  final String label;
  const TajweedStyle(this.color, this.label);
}

const _abu = Color(0xFF9E9E9E);

const Map<String, TajweedStyle> tajweedStyles = {
  'hamzat_wasl': TajweedStyle(_abu, 'Hamzah wasal (tidak dibaca)'),
  'lam_shamsiyyah': TajweedStyle(_abu, 'Lam syamsiyah'),
  'silent': TajweedStyle(_abu, 'Huruf tidak dibaca'),
  'madd_2': TajweedStyle(Color(0xFF537FFF), 'Mad thabi\'i (2 harakat)'),
  'madd_246': TajweedStyle(Color(0xFF4050FF), 'Mad \'aridh/lin (2, 4, 6)'),
  'madd_munfasil': TajweedStyle(Color(0xFF3047D9), 'Mad jaiz munfashil (4-5)'),
  'madd_muttasil': TajweedStyle(Color(0xFF2144C1), 'Mad wajib muttashil (4-5)'),
  'madd_6': TajweedStyle(Color(0xFF000EBC), 'Mad lazim (6 harakat)'),
  'ghunnah': TajweedStyle(Color(0xFFFF7E1E), 'Ghunnah'),
  'qalqalah': TajweedStyle(Color(0xFFDD0008), 'Qalqalah'),
  'ikhfa': TajweedStyle(Color(0xFF9400A8), 'Ikhfa\''),
  'ikhfa_shafawi': TajweedStyle(Color(0xFFD500B7), 'Ikhfa\' syafawi'),
  'iqlab': TajweedStyle(Color(0xFF26BFFD), 'Iqlab'),
  'idghaam_ghunnah': TajweedStyle(Color(0xFF169777), 'Idgham bighunnah'),
  'idghaam_no_ghunnah': TajweedStyle(Color(0xFF169200), 'Idgham bilaghunnah'),
  'idghaam_shafawi': TajweedStyle(Color(0xFF58B800), 'Idgham mimi'),
  'idghaam_mutajanisayn': TajweedStyle(_abu, 'Idgham mutajanisain'),
  'idghaam_mutaqaribayn': TajweedStyle(_abu, 'Idgham mutaqaribain'),
};
