import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../contracts/ledger_snapshot_store.dart';
import '../models/persisted_service_ledger_entry.dart';
import '../models/runtime_snapshot_provenance.dart';
import '../../domain/entities/service_ledger_entry.dart';

class JsonFileLedgerSnapshotStore implements LedgerSnapshotStore {
  factory JsonFileLedgerSnapshotStore.applicationSupport({
    Future<Directory> Function()? directoryProvider,
    String fileName = defaultFileName,
  }) {
    return JsonFileLedgerSnapshotStore._(
      directoryProvider: directoryProvider ?? getApplicationSupportDirectory,
      fileName: fileName,
    );
  }

  const JsonFileLedgerSnapshotStore._({
    required Future<Directory> Function() directoryProvider,
    required String fileName,
  })  : _directoryProvider = directoryProvider,
        _fileName = fileName;

  static const String defaultFileName = 'ledger_snapshot.json';

  final Future<Directory> Function() _directoryProvider;
  final String _fileName;

  @override
  Future<bool> hasSnapshot() async {
    try {
      final file = await _snapshotFile(createDirectory: false);
      return file.exists();
    } on MissingPluginException {
      return false;
    } on MissingPlatformDirectoryException {
      return false;
    } on FileSystemException {
      return false;
    }
  }

  @override
  Future<List<ServiceLedgerEntry>> load() async {
    final record = await loadRecord();
    return record?.entries ?? const <ServiceLedgerEntry>[];
  }

  @override
  Future<LedgerSnapshotRecord?> loadRecord() async {
    try {
      final file = await _snapshotFile(createDirectory: false);
      if (!await file.exists()) {
        return null;
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return LedgerSnapshotRecord(
          entries: _parseEntries(decoded),
        );
      }

      if (decoded is! Map) {
        return null;
      }

      final rawEntries = decoded['entries'];
      if (rawEntries is! List) {
        return null;
      }

      final rawMetadata = decoded['metadata'];
      return LedgerSnapshotRecord(
        entries: _parseEntries(rawEntries),
        metadata: rawMetadata is Map
            ? LedgerSnapshotMetadata.fromJson(
                rawMetadata.map(
                  (key, value) => MapEntry(key.toString(), value),
                ),
              )
            : null,
      );
    } on MissingPluginException {
      return null;
    } on MissingPlatformDirectoryException {
      return null;
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> save(List<ServiceLedgerEntry> entries) async {
    await saveRecord(LedgerSnapshotRecord(entries: entries));
  }

  @override
  Future<void> saveRecord(LedgerSnapshotRecord record) async {
    try {
      final file = await _snapshotFile(createDirectory: true);
      final persistedEntries = record.entries.toList(growable: false)
        ..sort(
          (left, right) => left.serviceKey.value.compareTo(right.serviceKey.value),
        );
      final payload = <String, Object?>{
        'entries': persistedEntries
            .map(
              (entry) => PersistedServiceLedgerEntry.fromDomain(entry).toJson(),
            )
            .toList(growable: false),
        if (record.metadata != null) 'metadata': record.metadata!.toJson(),
      };

      await file.writeAsString(jsonEncode(payload), flush: true);
    } on MissingPluginException {
      return;
    } on MissingPlatformDirectoryException {
      return;
    } on FileSystemException {
      return;
    }
  }

  Future<File> _snapshotFile({required bool createDirectory}) async {
    final directory = await _directoryProvider();
    if (createDirectory && !await directory.exists()) {
      await directory.create(recursive: true);
    }

    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }

  List<ServiceLedgerEntry> _parseEntries(List<dynamic> rawEntries) {
    return rawEntries
        .whereType<Map>()
        .map(
          (item) => PersistedServiceLedgerEntry.fromJson(
            item.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          ).toDomain(),
        )
        .toList(growable: false);
  }
}
