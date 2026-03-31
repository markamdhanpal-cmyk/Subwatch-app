import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../contracts/sms_onboarding_progress_store.dart';
import 'atomic_json_file_writer.dart';

class JsonFileSmsOnboardingProgressStore implements SmsOnboardingProgressStore {
  factory JsonFileSmsOnboardingProgressStore.applicationSupport({
    Future<Directory> Function()? directoryProvider,
    String fileName = defaultFileName,
  }) {
    return JsonFileSmsOnboardingProgressStore._(
      directoryProvider: directoryProvider ?? getApplicationSupportDirectory,
      fileName: fileName,
    );
  }

  const JsonFileSmsOnboardingProgressStore._({
    required Future<Directory> Function() directoryProvider,
    required String fileName,
  })  : _directoryProvider = directoryProvider,
        _fileName = fileName;

  static const String defaultFileName = 'sms_onboarding_progress.json';

  final Future<Directory> Function() _directoryProvider;
  final String _fileName;

  @override
  Future<bool> readCompleted() async {
    try {
      final file = await _dataFile(createDirectory: false);
      final raw = await AtomicJsonFileWriter.read(file);
      if (raw == null) {
        return false;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return false;
      }

      return decoded['completed'] == true;
    } on MissingPluginException {
      return false;
    } on MissingPlatformDirectoryException {
      return false;
    } on FileSystemException {
      return false;
    } on FormatException {
      return false;
    } on TypeError {
      return false;
    }
  }

  @override
  Future<void> writeCompleted(bool completed) async {
    try {
      final file = await _dataFile(createDirectory: true);
      final payload = jsonEncode(<String, Object?>{
        'completed': completed,
      });
      await AtomicJsonFileWriter.write(file, payload);
    } on MissingPluginException {
      return;
    } on MissingPlatformDirectoryException {
      return;
    } on FileSystemException {
      return;
    }
  }

  @override
  Future<void> clear() async {
    try {
      final file = await _dataFile(createDirectory: false);
      if (await file.exists()) {
        await file.delete();
      }
    } on MissingPluginException {
      return;
    } on MissingPlatformDirectoryException {
      return;
    } on FileSystemException {
      return;
    }
  }

  Future<File> _dataFile({required bool createDirectory}) async {
    final directory = await _directoryProvider();
    if (createDirectory && !await directory.exists()) {
      await directory.create(recursive: true);
    }

    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }
}
