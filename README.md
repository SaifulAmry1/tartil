# Tartil

**T**erjadwal, **R**utin, **T**eratur, **I**ngat, **L**ancar. Aplikasi Android (Flutter) untuk jadwal murojaah hafalan Al-Qur'an, untuk anak maupun dewasa. Tanpa login, tanpa server, gratis.

## Fitur v0.1

- Multi profil di satu HP. Tiap profil punya rentang hafalan (per juz atau per surah), jumlah hari per siklus, dan jam pengingat harian.
- Jadwal seimbang: rentang dibagi ke N hari dengan durasi baca harian yang mirip, memadukan surah panjang dan pendek. Surah dibiarkan utuh; hanya surah yang terlalu panjang yang dipotong per ayat.
- Hari terlewat dihitung ulang otomatis agar tetap selesai dalam siklus. Hari ditandai selesai lewat tombol **Selesai**.
- Mushaf per halaman (Madinah 15 baris) dengan 8 blok warna dan warna tajwid.
- Rekam murojaah (opsional): pengenal suara on-device memeriksa kata yang salah atau terlewat, memberi nilai, dan surah bernilai di bawah 80 dijadwalkan ulang lebih sering.
- Menu **Uji suara** untuk menguji akurasi pengenal suara pada suara anak dan dewasa.

## Memasang APK

Setiap push ke `main` membangun APK lewat GitHub Actions dan menerbitkannya di halaman **Releases** (`tartil-arm64.apk`). Buka dari HP Android, unduh, lalu pasang (izinkan "pasang dari sumber tak dikenal").

Agar versi baru bisa langsung menimpa versi lama (data profil tetap aman), APK ditandatangani dengan kunci tetap dari secret repo `TARTIL_KEYSTORE_B64` (keystore PKCS12 dalam base64, alias `tartil`) dan `TARTIL_KEYSTORE_PASSWORD`. Tanpa secret itu, CI memakai kunci debug yang berganti tiap build.

## Pengembangan

```bash
flutter pub get
flutter test
```

Data Qur'an (`assets/quran/quran.json`) dibuat dengan `tool/build_quran_data.py` dari:

| Data | Sumber | Lisensi |
|---|---|---|
| Teks Utsmani | Tanzil Quran Text (Uthmani 1.0.2), tanzil.net | CC BY 3.0, disalin apa adanya |
| Anotasi tajwid | cpfair/quran-tajweed | CC BY 4.0 |
| Halaman & baris | quran-ws/quran-text (Hafs, Madinah 15 baris) | CC BY 4.0 |
| Font | Amiri Quran | SIL OFL 1.1 |
| Pengenal suara | whisper.cpp + tarteel-ai/whisper-base-ar-quran | MIT / lihat kartu model |

Model suara tidak disimpan di repo. CI mengunduh model dari Hugging Face, mengonversinya ke GGML (q5_1), lalu membundelnya ke APK.
