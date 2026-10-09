/// One-tap in-app updates from your own server.
///
/// The server stages `PetTrack.apk` + `update.json` in its updates/
/// directory (see docs/RELEASE_CHECKLIST.md); Settings → About probes for
/// it, downloads it and hands it to the Android installer. Nothing leaves
/// the LAN, and there is no third-party update service in the middle.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../app_info.dart';
import 'auth_service.dart';

/// A newer APK staged on the server, ready to download.
class AppUpdate {
  final String version;
  final int sizeBytes;

  const AppUpdate({required this.version, this.sizeBytes = 0});

  /// Builds an [AppUpdate] from the `/api/app/update` payload, or null
  /// when the server has nothing staged or nothing newer than [current].
  static AppUpdate? fromPayload(
    Map<String, dynamic> data, {
    String currentVersion = kAppVersion,
  }) {
    final version = (data['version'] as String?)?.trim();
    if (version == null || version.isEmpty) return null;
    if (!updateIsNewer(version, currentVersion)) return null;
    return AppUpdate(
      version: version,
      sizeBytes: (data['apk_bytes'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Is [latest] worth installing over [current]?
bool updateIsNewer(String latest, String current) =>
    compareVersions(latest, current) > 0;

/// Asks the server what it has staged. Never throws: no staged update,
/// a missing endpoint on an older server and a dead server all mean "no
/// update available" — the About card just stays quiet.
Future<AppUpdate?> checkForAppUpdate(String serverBase) async {
  try {
    final response = await http
        .get(Uri.parse('$serverBase/api/app/update'))
        .timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) return null;
    return AppUpdate.fromPayload(data);
  } catch (_) {
    return null;
  }
}

/// Downloads the staged APK into the cache dir, reporting progress.
/// Throws [HttpException] when the server refuses or the stream dies.
Future<File> downloadAppUpdate(
  String serverBase,
  AppUpdate update, {
  void Function(int received, int total)? onProgress,
}) async {
  final client = http.Client();
  try {
    final request = http.Request(
      'GET',
      Uri.parse('$serverBase/api/app/update/apk'),
    );
    request.headers.addAll(AuthService.headers);
    final response = await client.send(request);
    if (response.statusCode != 200) {
      throw const HttpException('update download refused');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/PetTrack-update.apk');
    final sink = file.openWrite();
    final total = response.contentLength ?? update.sizeBytes;
    var received = 0;
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    return file;
  } finally {
    client.close();
  }
}

/// Opens the Android installer on a downloaded APK. The system shows its
/// own confirmation — the app can stage the install, never approve it.
Future<void> installDownloadedUpdate(File apk) async {
  await _updater.invokeMethod<void>('installApk', <String, String>{
    'path': apk.path,
  });
}

const MethodChannel _updater = MethodChannel('pettrack/updater');
