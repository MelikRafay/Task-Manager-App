// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

/// Triggers a browser download of [bytes].
Future<void> saveBytes(String name, Uint8List bytes, String mime) async {
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final a = html.AnchorElement(href: url)
    ..download = name
    ..style.display = 'none';
  html.document.body?.append(a);
  a.click();
  a.remove();
  html.Url.revokeObjectUrl(url);
}

/// Plays a short generated tone. The pitch depends on the chosen sound.
Future<void> playBeep(String soundId) async {
  if (soundId == 'silent') return;
  final freq = switch (soundId) {
    'ringtone' => 880.0,
    'alarm' => 1200.0,
    _ => 660.0,
  };
  final beeps = soundId == 'alarm' ? 3 : 1;
  try {
    final wav = _makeWav(freq, beeps);
    final audio =
        html.AudioElement('data:audio/wav;base64,${base64Encode(wav)}');
    await audio.play();
  } catch (_) {
    // Browsers may block audio before the first user interaction.
  }
}

Uint8List _makeWav(double freq, int beeps) {
  const sampleRate = 22050;
  const beepSec = 0.25;
  const gapSec = 0.12;
  final samplesPerBeep = (sampleRate * beepSec).toInt();
  final samplesGap = (sampleRate * gapSec).toInt();
  final total = beeps * samplesPerBeep + (beeps - 1) * samplesGap;
  final data = ByteData(44 + total * 2);

  void writeStr(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  writeStr(0, 'RIFF');
  data.setUint32(4, 36 + total * 2, Endian.little);
  writeStr(8, 'WAVE');
  writeStr(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  writeStr(36, 'data');
  data.setUint32(40, total * 2, Endian.little);

  var pos = 44;
  for (var b = 0; b < beeps; b++) {
    for (var i = 0; i < samplesPerBeep; i++) {
      final fade = math.min(1.0, math.min(i, samplesPerBeep - i) / 800);
      final v = math.sin(2 * math.pi * freq * i / sampleRate) * 0.5 * fade;
      data.setInt16(pos, (v * 32767).toInt(), Endian.little);
      pos += 2;
    }
    if (b < beeps - 1) pos += samplesGap * 2; // silence (already zero)
  }
  return data.buffer.asUint8List();
}

Future<void> requestBrowserNotificationPermission() async {
  try {
    if (html.Notification.supported &&
        html.Notification.permission == 'default') {
      await html.Notification.requestPermission();
    }
  } catch (_) {}
}

Future<void> showBrowserNotification(String title, String body) async {
  try {
    if (html.Notification.supported &&
        html.Notification.permission == 'granted') {
      html.Notification(title, body: body);
    }
  } catch (_) {}
}
