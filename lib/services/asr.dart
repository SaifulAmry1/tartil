// Versi web (pratinjau di browser) tidak punya pengenal suara on-device.
export 'asr_web.dart' if (dart.library.ffi) 'asr_io.dart';
