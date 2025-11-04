import 'dart:typed_data';
import 'dart:html' as html; // Web only
import 'package:share_plus/share_plus.dart';

import 'qrSaver.dart';

class _QrSaverWeb implements QrSaver {
  @override
  Future<String> savePng(Uint8List bytes, {String fileName = 'referral_qr.png'}) async {
    final blob = html.Blob([bytes], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';
    html.document.body!.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    return 'downloaded';
  }

  @override
  Future<void> sharePng(Uint8List bytes, {String? text, String fileName = 'referral_qr.png'}) async {
    // Le partage de fichier n'est pas toujours supporté par le Web Share API.
    // On assure un fallback en partageant le texte (referral code) si besoin.
    await Share.share(text ?? 'Mon code parrainage');
  }
}

QrSaver createQrSaver() => _QrSaverWeb();
