import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Saves [bytes] to a temp file and opens the system share sheet
/// (save to Files / Drive, send by email, ...).
Future<void> saveBytes(String name, Uint8List bytes, String mime) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path, mimeType: mime)], subject: name);
}

Future<void> playBeep(String soundId) async {
  if (soundId == 'silent') return;
  await SystemSound.play(SystemSoundType.alert);
}

Future<void> requestBrowserNotificationPermission() async {}

Future<void> showBrowserNotification(String title, String body) async {}
