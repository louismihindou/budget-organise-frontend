// TODO Implement this library.import 'dart:typed_data';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'qrSaver.dart';

class _QrSaverIo implements QrSaver {
  @override
  Future<String> savePng(Uint8List bytes, {String fileName = 'referral_qr.png'}) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<void> sharePng(Uint8List bytes, {String? text, String fileName = 'referral_qr.png'}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)], text: text);
  }
}

QrSaver createQrSaver() => _QrSaverIo();
