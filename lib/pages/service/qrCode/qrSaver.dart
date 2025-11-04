import 'dart:typed_data';

abstract class QrSaver {
  Future<String> savePng(Uint8List bytes, {String fileName = 'referral_qr.png'});
  Future<void> sharePng(Uint8List bytes, {String? text, String fileName = 'referral_qr.png'});
}

// fourni par les implémentations
QrSaver createQrSaver() {
  throw UnimplementedError();
}

final qrSaver = createQrSaver();
