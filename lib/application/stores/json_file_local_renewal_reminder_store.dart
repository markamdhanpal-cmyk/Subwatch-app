import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../contracts/local_renewal_reminder_store.dart';
import '../models/local_renewal_reminder_models.dart';

class JsonFileLocalRenewalReminderStore
    implements LocalRenewalReminderStore {
  factory JsonFileLocalRenewalReminderStore.applicationSupport({
    Future<Directory> Function()? directoryProvider,
    String fileName = defaultFileName,
  }) {
    return JsonFileLocalRenewalReminderStore._(
      directoryProvider: directoryProvider ?? getApplicationSupportDirectory,
      fileName: fileName,
    );
  }

  const JsonFileLocalRenewalReminderStore._({
    required Future<Directory> Function() directoryProvider,
    required String fileName,
  })  : _directoryProvider = directoryProvider,
        _fileName = fileName;

  static const String defaultFileName = 'local_renewal_reminders.json';

  final Future<Directory> Function() _directoryProvider;
  final String _fileName;

  @override
  Future<List<LocalRenewalReminderPreference>> list() async {
    try {
      final file = await _dataFile(createDirectory: false);
      if (!await file.exists()) {
        return const <LocalRenewalReminderPreference>[];
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const <LocalRenewalReminderPreference>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <LocalRenewalReminderPreference>[];
      }

      final preferences = decoded
          .whereType<Map>()
          .map(
            (item) => LocalRenewalReminderPreference.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(growable: false)
        ..sort((left, right) => left.serviceKey.compareTo(right.serviceKey));
      return preferences;
    } on MissingPluginException {
      return const <LocalRenewalReminderPreference>[];
    } on MissingPlatformDirectoryException {
      return const <LocalRenewalReminderPreference>[];
    } on FileSystemException {
      return const <LocalRenewalReminderPreference>[];
    } on FormatException {
      return const <LocalRenewalReminderPreference>[];
    } on TypeError {
      return const <LocalRenewalReminderPreference>[];
    }
  }

  @override
  Future<void> save(LocalRenewalReminderPreference preference) async {
    try {
      final existing = await list();
      final next = <String, LocalRenewalReminderPreference>{
        for (final item in existing) item.serviceKey: item,
        preference.serviceKey: preference,
      }.values.toList(growable: false)
        ..sort((left, right) => left.serviceKey.compareTo(right.serviceKey));

      final file = await _dataFile(createDirectory: true);
      final payload =
          next.map((item) => item.toJson()).toList(growable: false);
      await file.writeAsString(jsonEncode(payload), flush: true);
    } on MissingPluginException {
      return;
    } on MissingPlatformDirectoryException {
      return;
    } on FileSystemException {
      return;
    }
  }

  @override
  Future<bool> remove(String serviceKey) async {
    try {
      final existing = await list();
      final next = existing
          .where((item) => item.serviceKey != serviceKey)
          .toList(growable: false);
      if (next.length == existing.length) {
        return false;
      }

      final file = await _dataFile(createDirectory: true);
      final payload =
          next.map((item) => item.toJson()).toList(growable: false);
      await file.writeAsString(jsonEncode(payload), flush: true);
      return true;
    } on MissingPluginException {
      return false;
    } on MissingPlatformDirectoryException {
      return false;
    } on FileSystemException {
      return false;
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
