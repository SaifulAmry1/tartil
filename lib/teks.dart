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
  static const selesai = 'Selesai';
  static const sudah = 'Sudah';
  static const tandaiSemua = 'Tandai semua selesai';
  static String sebagian(int n, int total) => '$n dari $total bacaan selesai';
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
  static const hariLibur = 'Hari libur';
  static const hariLiburKet = 'Tidak dihitung dalam siklus dan tidak dianggap terlewat.';
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
  static String liburHariIni(String hari) => 'Hari ini $hari, jadwal libur murojaah.';
  static const liburBesok = 'Murojaah berikutnya';
  static const rekam = 'Rekam';
  static const baca = 'Baca';
  static String menit(double detik) {
    final m = detik / 60;
    return m < 1 ? '< 1 menit' : '± ${m.round()} menit';
  }
  static String ayat(int dari, int sampai) => 'ayat $dari-$sampai';
  static const alhamdulillah = 'Alhamdulillah, murojaah hari ini selesai.';
  static const hariSebelumnya = 'Hari sebelumnya';
  static const hariBerikutnya = 'Hari berikutnya';
  static const selesaiLebihAwal = 'Sudah dimurojaah lebih awal';
  static const tandaiLebihAwal = 'Murojaah lebih awal, tandai selesai';
  static String lebihAwalKet(String hari) =>
      'Bacaan $hari ini boleh dimurojaah sekarang. Setelah ditandai selesai, hari $hari nanti sudah beres.';
  static const geserHari = 'Geser kiri atau kanan untuk pindah hari';
  static const lanjutBesok = 'Mau lanjut? Murojaah bacaan hari berikutnya';
  static const siklus = 'Siklus murojaah';
  static const pilihSiklus = 'Jumlah hari per siklus';
  static const pilihSiklusKet =
      'Seluruh rentang hafalan selesai dalam jumlah hari ini. Mengubahnya membuat jadwal baru mulai hari ini.';
  static const lainnyaSiklus = 'Angka lain...';
  static String konfirmasiSiklus(int n) =>
      'Ubah siklus menjadi $n hari? Jadwal dibuat ulang mulai hari ini dan tanda selesai siklus ini dihapus.';
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
  static String memprosesKet(String panjang) =>
      'Rekaman $panjang. Pemeriksaan di HP bisa memakan waktu sekitar sepanjang rekaman. Layar boleh tetap terbuka.';
  static const batalPeriksa = 'Batalkan pemeriksaan';
  static const periksaMacet =
      'Pemeriksaan terhenti karena terlalu lama tanpa kemajuan. Coba rekam per surah atau per beberapa ayat saja.';
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

  // Pantauan orang tua
  static const pantauOrtu = 'Pantauan orang tua';
  static const pantauOrtuKet =
      'Orang tua cukup memindai QR ini sekali: dengan aplikasi Tartil di HP orang tua (Profil > Pantau anak), '
      'atau dengan kamera HP biasa untuk membuka versi web. Setelah itu kemajuan murojaah, termasuk hasil rekaman, '
      'terbarui sendiri. Tanpa akun.';
  static const pantauOrtuCatatan =
      'Data terkirim otomatis setiap ada perubahan selama HP tersambung internet. Tanpa internet, data dikirim '
      'begitu tersambung lagi. Simpan link ini hanya untuk orang tua.';
  static const sinkronProses = 'Menyinkronkan...';
  static const sinkronGagal = 'Belum tersinkron. Periksa internet.';
  static String sinkronOk(String waktu) => 'Tersinkron $waktu';
  static const cobaLagi = 'Coba lagi';
  static const muatUlang = 'Muat ulang';
  static String lapDiperbarui(String waktu) => 'Diperbarui $waktu';
  static String lapTanpaAktivitas(int hari) =>
      'Belum ada aktivitas di aplikasi sejak $hari hari lalu.';
  static const lapRekaman = 'Hasil rekaman terbaru';
  static String lapRekamanTerakhir(String surah, int nilai) => 'Rekaman terakhir: $surah, nilai $nilai';
  static const lapLibur = 'Libur';
  static const ortuJudul = 'Pantauan murojaah';
  static String ortuKet(int n) => n == 0 ? 'Belum ada anak yang dipantau' : '$n anak dipantau';
  static const ortuKosong = 'Pindai QR di aplikasi Tartil milik anak untuk mulai memantau.';
  static const pantauAnak = 'Pantau anak (orang tua)';
  static const memuat = 'Memuat...';
  static const pantauAnakJudul = 'Pantau anak';
  static const pantauAnakMulai = 'Tambah anak untuk dipantau';
  static const pantauAnakSub = 'Pindai QR dari HP anak, kemajuannya terbarui otomatis';
  static const sayaOrtu = 'Saya orang tua, pantau anak';
  static const tambahAnak = 'Tambah anak';
  static const pindaiQr = 'Pindai QR anak';
  static const pindaiQrSub = 'Buka Profil > Pantauan orang tua di HP anak';
  static const pindaiQrKet = 'Arahkan kamera ke QR di HP anak (Profil > Pantauan orang tua).';
  static const qrBukanTartil = 'QR ini bukan QR pantauan Tartil.';
  static const izinKamera = 'Izin kamera dibutuhkan untuk memindai QR. Aktifkan di pengaturan HP.';
  static const tempelLink = 'Tempel link pantauan';
  static const tempelLinkSub = 'Link yang dikirim dari HP anak lewat WhatsApp';
  static const linkTidakValid = 'Link tidak dikenali. Pastikan link pantauan dari aplikasi Tartil.';
  static const tambah = 'Tambah';
  static const ortuCatatanApp =
      'Laporan memperbarui sendiri tiap 30 detik selama layar ini terbuka. Tarik ke bawah untuk memuat ulang.';
  static const ortuBelumAda = 'Data belum tersedia. Pastikan HP anak tersambung internet.';
  static const ortuCatatan =
      'Halaman ini memperbarui sendiri tiap 30 detik. Simpan sebagai bookmark atau tambahkan ke layar utama. '
      'Untuk memantau anak lain, pindai QR dari HP anak tersebut.';
  static const kirimLaporan = 'Kirim laporan (WhatsApp, dll.)';
  static const salinLink = 'Salin link';
  static const linkDisalin = 'Link laporan disalin';
  static const lihatLaporan = 'Lihat laporan seperti orang tua';
  static const lapNamaHalaman = 'Laporan murojaah';
  static String lapJudul(String nama, String rentang) => 'Laporan murojaah $nama ($rentang)';
  static String lapAngka(int selesai, int total, int terlewat, int beruntun) =>
      'Selesai $selesai/$total hari · terlewat $terlewat · beruntun $beruntun hari';
  static const lapHariIniSelesai = 'Murojaah hari ini sudah selesai.';
  static const lapHariIniBelum = 'Murojaah hari ini belum selesai.';
  static const lapLihat = 'Lihat detail';
  static String lapDibuat(String waktu) => 'Dibagikan $waktu';
  static String lapKedaluwarsa(int hari) =>
      'Laporan ini dibagikan $hari hari lalu. Minta anak membagikan ulang untuk melihat kemajuan terbaru.';
  static const lapRiwayat = 'Hari per hari';
  static const lapSelesai = 'Selesai';
  static const lapTerlewat = 'Terlewat';
  static const lapBelum = 'Belum';
  static const lapHariIni = 'Hari ini';
  static const lapRusak = 'Link laporan tidak bisa dibaca. Minta anak membagikan ulang dari aplikasi Tartil.';

  // Notifikasi
  static const kanalNama = 'Pengingat murojaah';
  static const kanalKet = 'Pengingat harian jadwal murojaah';
  static String notifJudul(String nama) => 'Waktunya murojaah, $nama';
  static const notifIsi = 'Buka Tartil untuk melihat bacaan hari ini.';
}
