// Pengenal suara on-device: whisper.cpp dengan model Whisper yang dilatih
// untuk bacaan Al-Qur'an (tarteel-ai/whisper-base-ar-quran, dikonversi ke
// GGML saat build). Gratis, tanpa server, berjalan offline.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

class Asr {
  static const _asset = 'assets/model/ggml-quran.bin';
  // Model deteksi suara (Silero VAD): memotong jeda diam sebelum diproses,
  // sehingga pemeriksaan lebih cepat dan Whisper tidak "mengarang" teks
  // berulang pada bagian hening.
  static const _vadAsset = 'assets/model/ggml-vad.bin';

  /// Naikkan setiap kali model di APK berganti, agar salinan lama diganti.
  static const _modelVersion = 3;
  static const _vadVersion = 1;
  static String? _modelPath;
  static String? _vadPath;
  static bool _vadBroken = false;

  /// true jika model ikut dibundel di APK ini.
  static Future<bool> available() async {
    try {
      final m = await AssetManifest.loadFromAssetBundle(rootBundle);
      return m.listAssets().contains(_asset);
    } catch (_) {
      return false;
    }
  }

  /// Salin aset ke penyimpanan aplikasi (sekali saja). Ditulis ke berkas
  /// sementara lalu diganti nama, jadi berkas yang ada pasti utuh.
  static Future<String> _copy(String asset, String prefix, int version) async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$prefix-v$version.bin');
    for (final f in dir.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (name.startsWith(prefix) && f.path != file.path) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
    if (!await file.exists()) {
      final data = await rootBundle.load(asset);
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
      await tmp.rename(file.path);
    }
    return file.path;
  }

  static Future<String> prepare() async =>
      _modelPath ??= await _copy(_asset, 'ggml-quran', _modelVersion);

  static Future<String?> _vad() async {
    if (_vadBroken) return null;
    if (_vadPath != null) return _vadPath;
    try {
      final m = await AssetManifest.loadFromAssetBundle(rootBundle);
      if (!m.listAssets().contains(_vadAsset)) return null;
      return _vadPath = await _copy(_vadAsset, 'ggml-vad', _vadVersion);
    } catch (e) {
      debugPrint('VAD tidak tersedia: $e');
      return null;
    }
  }

  /// [onProgress] menerima 0-100 selama pemeriksaan berjalan.
  static Future<String> transcribe(String wavPath, {String? prompt, void Function(int)? onProgress}) async {
    final model = await prepare();
    final vad = await _vad();
    // Inti kecil (efisiensi) di HP big.LITTLE justru memperlambat bila
    // dipakai semua; 4 utas biasanya paling cepat.
    final threads = Platform.numberOfProcessors.clamp(2, 4);
    Future<String> run(String? vadPath) async {
      final res = await const Whisper(model: WhisperModel.base).transcribe(
        transcribeRequest: TranscribeRequest(
          audio: wavPath,
          language: 'ar',
          threads: threads,
          isNoTimestamps: true,
          initialPrompt: prompt,
          // Tanpa petunjuk teks, tiap potongan 30 detik diproses tanpa
          // bawaan teks sebelumnya: mencegah satu frasa salah berulang
          // terus sampai akhir rekaman (penyebab pemeriksaan sangat lama).
          maxContext: prompt == null ? 0 : null,
          suppressNonSpeechTokens: true,
          keepModelLoaded: true,
          vadModelPath: vadPath,
          vadSpeechPadMs: vadPath == null ? null : 200,
        ),
        modelPath: model,
        onProgress: onProgress,
      );
      return res.text;
    }

    String text;
    try {
      text = await run(vad);
    } catch (e) {
      if (vad == null) rethrow;
      // Model VAD bermasalah di HP ini: lanjutkan tanpa VAD.
      debugPrint('ASR dengan VAD gagal ($e), ulang tanpa VAD');
      _vadBroken = true;
      text = await run(null);
    }
    debugPrint('ASR: $text');
    return text;
  }
}
