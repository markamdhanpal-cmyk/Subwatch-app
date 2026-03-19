import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../contracts/local_manual_subscription_store.dart';
import '../models/manual_subscription_models.dart';

class JsonFileLocalManualSubscriptionStore
    implements LocalManualSubscriptionStore {
  factory JsonFileLocalManualSubscriptionStore.applicationSupport({
    Future<Directory> Function()? directoryProvider,
    String fileName = defaultFileName,
  }) {
    return JsonFileLocalManualSubscriptionStore._(
      directoryProvider: directoryProvider ?? getApplicationSupportDirectory,
      fileName: fileName,
    );
  }

  const JsonFileLocalManualSubscriptionStore._({
    required Future<Directory> Function() directoryProvider,
    required String fileName,
  })  : _directoryProvider = directoryProvider,
        _fileName = fileName;

  static const String defaultFileName = 'local_manual_subscriptions.json';

  final Future<Directory> Function() _directoryProvider;
  final String _fileName;

  @override
  Future<List<ManualSubscriptionEntry>> list() async {
    try {
      final file = await _dataFile(createDirectory: false);
      if (!await file.exists()) {
        return const <ManualSubscriptionEntry>[];
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const <ManualSubscriptionEntry>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <ManualSubscriptionEntry>[];
      }

      final entries = decoded
          .whereType<Map>()
          .map(
            (item) => ManualSubscriptionEntry.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(growable: false)
        ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
      return entries;
    } on MissingPluginException {
      return const <ManualSubscriptionEntry>[];
    } on MissingPlatformDirectoryException {
      return const <ManualSubscriptionEntry>[];
    } on FileSystemException {
      return const <ManualSubscriptionEntry>[];
    } on FormatException {
      return const <ManualSubscriptionEntry>[];
    } on TypeError {
      return const <ManualSubscriptionEntry>[];
    }
  }

  @override
  Future<void> save(ManualSubscriptionEntry entry) async {
    try {
      final existing = await list();
      final next = <String, ManualSubscriptionEntry>{
        for (final item in existing) item.id: item,
        entry.id: entry,
      }.values.toList(growable: false)
        ..sort((left, right) => left.createdAt.compareTo(right.createdAt));

      final file = await _dataFile(createDirectory: true);
      final payload = next.map((item) => item.toJson()).toList(growable: false);
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
  Future<bool> remove(String id) async {
    try {
      final existing = await list();
      final next =
          existing.where((item) => item.id != id).toList(growable: false);
      if (next.length == existing.length) {
        return false;
      }

      final file = await _dataFile(createDirectory: true);
      final payload = next.map((item) => item.toJson()).toList(growable: false);
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
