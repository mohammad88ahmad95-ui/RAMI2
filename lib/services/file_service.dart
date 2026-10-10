import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/errors.dart';

Future<File> writeTempFile(String name, List<int> bytes) async {
  try {
    final dir = await getTemporaryDirectory();
    final f = File(p.join(dir.path, name));
    return await f.writeAsBytes(bytes, flush: true);
  } catch (_) {
    throw const AppException('تعذّر إنشاء الملف. حاول مرة أخرى.');
  }
}

Future<void> shareFile(File file, {required String mime, String? subject, String? text}) async {
  try {
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mime)],
      subject: subject,
      text: text,
    );
  } catch (_) {
    throw const AppException('تعذّرت مشاركة الملف. حاول مرة أخرى.');
  }
}
