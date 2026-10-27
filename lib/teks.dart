// Semua teks antarmuka (bahasa Indonesia) dikumpulkan di sini, terpisah
// dari kode tampilan.
class Teks {
  static const appName = 'Tartil';
  static const kepanjangan = 'Terjadwal, Rutin, Teratur, Ingat, Lancar';

  // Beranda
  static const profilKosong = 'Belum ada profil.\nTambahkan profil untuk mulai membuat jadwal murojaah.';
  static const tambahProfil = 'Tambah profil';
  static const ujiSuara = 'Uji suara';
  static const tentang = 'Tentang & lisensi';
  static const bacaMushaf = 'Baca mushaf';
  static String hariKe(int hari, int total) => 'Hari ke-$hari dari $total';
  static String siklusKe(int n) => 'Siklus ke-$n';
  static const sudahSelesai = 'Selesai hari ini';
  static const belumSelesai = 'Belum dibaca';

  // Form profil
  static const profilBaru = 'Profil baru';
  static const ubahProfil = 'Ubah profil';
  static const nama = 'Nama';
  static const namaKosong = 'Nama wajib diisi';
  static const rentang = 'Rentang hafalan';
  static const perJuz = 'Per juz';
  static const perSurah = 'Per surah';
  static const pilihJuz = 'Pilih juz';
  static const juzKosong = 'Pilih minimal satu juz';
  static const dariSurah = 'Dari surah';
  static const sampaiSurah = 'Sampai surah';
  static const jumlahHari = 'Jumlah hari per siklus';
  static const hariTidakSah = 'Isi angka 1 sampai 365';
  static const pengingat = 'Pengingat harian';
  static const simpan = 'Simpan';
  static const hapus = 'Hapus profil';
  static String konfirmasiHapus(String n) => 'Hapus profil "$n" beserta riwayatnya?';
  static const batal = 'Batal';
  static const ya = 'Ya';
  static const mulaiUlangSiklus = 'Rentang atau jumlah hari berubah. Jadwal dibuat ulang mulai hari ini.';

  // Jadwal
  static const jadwalHariIni = 'Murojaah hari ini';
  static const semuaJadwal = 'Seluruh siklus';
  static const tandaiSelesai = 'Selesai';
  static const batalSelesai = 'Batalkan tanda selesai';
  static const ulang = 'Ulang';
  static const terlewat = 'Terlewat, dipindah ke hari lain';
  static const libur = 'Tidak ada bacaan';
  static const rekam = 'Rekam';
  static const baca = 'Baca';
  static String menit(double detik) {
    final m = detik / 60;
    return m < 1 ? '< 1 menit' : '± ${m.round()} menit';
  }
  static String ayat(int dari, int sampai) => 'ayat $dari-$sampai';
  static const alhamdulillah = 'Alhamdulillah, murojaah hari ini selesai.';
  static String nilai(int n) => 'Nilai $n';

  // Mushaf
  static String halaman(int n) => 'Halaman $n';
  static const tajwid = 'Warna tajwid';
  static const blok = '8 blok warna';
  static const keteranganTajwid = 'Keterangan warna';

  // Rekam
  static const rekamMurojaah = 'Rekam murojaah';
  static const mulaiRekam = 'Mulai rekam';
  static const berhenti = 'Berhenti & periksa';
  static const merekam = 'Merekam...';
  static const memproses = 'Memeriksa bacaan...';
  static const izinMikrofon = 'Izin mikrofon dibutuhkan untuk merekam.';
  static const modelTidakAda = 'Model pengenal suara belum ada di versi aplikasi ini.';
  static const rekamHanyaAndroid = 'Rekam suara hanya tersedia di aplikasi Android. Versi web ini untuk pratinjau tampilan.';
  static const menyiapkanModel = 'Menyiapkan model suara (sekali saja)...';
  static const hasil = 'Hasil pemeriksaan';
  static const kataSalah = 'Kata salah';
  static const kataTerlewat = 'Terlewat';
  static const kataTambahan = 'Kata tambahan terdengar';
  static const terdengar = 'terdengar';
  static const seharusnya = 'seharusnya';
  static const semuaBenar = 'Semua kata terbaca. Masya Allah!';
  static const detailTeknis = 'Detail teknis';
  static String waktuProses(Duration rek, Duration proses) =>
      'Rekaman ${rek.inSeconds} detik, diproses ${proses.inSeconds} detik';
  static const petunjukTeks = 'Beri petunjuk teks ke model';
  static const petunjukTeksKet =
      'Bisa menaikkan akurasi, tapi berisiko menutupi kesalahan bacaan. Untuk uji coba.';
  static const surahLemah = 'Nilai di bawah 80: surah ini dijadwalkan ulang lebih sering.';
  static const pilihSurah = 'Pilih surah';
  static const ujiSuaraKet =
      'Rekam bacaan satu surah, lalu lihat seberapa tepat aplikasi mengenali bacaan. '
      'Coba dengan suara anak dan dewasa, di tempat tenang dan agak ramai.';

  // Navigasi dan dasbor
  static const navBeranda = 'Beranda';
  static const navJadwal = 'Jadwal';
  static const navMushaf = 'Mushaf';
  static const navProfil = 'Profil';
  static const navMurojaah = 'Murojaah';
  static const salam = 'Assalamu\'alaikum,';
  static const kemajuanSiklus = 'Kemajuan siklus';
  static const hariBeruntun = 'Beruntun';
  static const hariSelesai = 'Selesai';
  static const hariTerlewat = 'Terlewat';
  static const rataNilai = 'Rata nilai';
  static const berikutnya = 'Jadwal berikutnya';
  static const perluDiulang = 'Perlu diulang';
  static const besok = 'Besok';
  static String hariLagi(int n) => '$n hari lagi';
  static String hariDari(int a, int b) => '$a/$b hari';
  static const selamatDatang = 'Selamat datang di Tartil';
  static const selamatDatangKet =
      'Atur jadwal murojaah hafalan untuk anak maupun dewasa. Buat profil pertama untuk memulai.';
  static const buatProfil = 'Buat profil';
  static const profilAktif = 'Profil aktif';
  static const gantiProfil = 'Ganti profil';
  static const lainnya = 'Lainnya';
  static const cariSurah = 'Cari surah';
  static String infoSurah(int ayat, int hal) => '$ayat ayat · hal. $hal';
  static const pengaturanProfil = 'Pengaturan profil';
  static String rentangJuz(List<int> j) => 'Juz ${j.join(', ')}';
  static String rentangSurah(String a, String b) => '$a sampai $b';
  static String siklusHari(int n) => 'Siklus $n hari';
  static String pengingatJam(String jam) => 'Pengingat $jam';

  // Notifikasi
  static const kanalNama = 'Pengingat murojaah';
  static const kanalKet = 'Pengingat harian jadwal murojaah';
  static String notifJudul(String nama) => 'Waktunya murojaah, $nama';
  static const notifIsi = 'Buka Tartil untuk melihat bacaan hari ini.';
}
