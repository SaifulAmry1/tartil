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

  /// Naikkan setiap kali model di APK berganti, agar salinan lama diganti.
  static const _modelVersion = 3;
  static String? _modelPath;

  /// true jika model ikut dibundel di APK ini.
  static Future<bool> available() async {
    try {
      final m = await AssetManifest.loadFromAssetBundle(rootBundle);
      return m.listAssets().contains(_asset);
    } catch (_) {
      return false;
    }
  }

  /// Salin model dari aset ke penyimpanan aplikasi (sekali saja).
  static Future<String> prepare() async {
    if (_modelPath != null) return _modelPath!;
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/ggml-quran-v$_modelVersion.bin');
    // Hapus salinan model versi lama.
    for (final f in dir.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (name.startsWith('ggml-quran') && f.path != file.path) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
    final data = await rootBundle.load(_asset);
    if (!await file.exists() || await file.length() != data.lengthInBytes) {
      await file.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true);
    }
    return _modelPath = file.path;
  }

  static Future<String> transcribe(String wavPath, {String? prompt}) async {
    final model = await prepare();
    final threads = Platform.numberOfProcessors.clamp(2, 6);
    final res = await const Whisper(model: WhisperModel.base).transcribe(
      transcribeRequest: TranscribeRequest(
        audio: wavPath,
        language: 'ar',
        threads: threads,
        isNoTimestamps: true,
        initialPrompt: prompt,
      ),
      modelPath: model,
    );
    debugPrint('ASR: ${res.text}');
    return res.text;
  }
}
