// Pengganti untuk versi web: rekam dan penilaian hanya ada di APK Android.
class Asr {
  static Future<bool> available() async => false;

  static Future<String> prepare() async => throw UnsupportedError('Hanya di Android');

  static Future<String> transcribe(String wavPath, {String? prompt, void Function(int)? onProgress}) async =>
      throw UnsupportedError('Hanya di Android');
}
