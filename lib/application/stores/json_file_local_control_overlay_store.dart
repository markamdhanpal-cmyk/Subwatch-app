import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../contracts/local_control_overlay_store.dart';
import '../models/local_control_overlay_models.dart';
import 'atomic_json_file_writer.dart';

class JsonFileLocalControlOverlayStore implements LocalControlOverlayStore {
  factory JsonFileLocalControlOverlayStore.applicationSupport({
    Future<Directory> Function()? directoryProvider,
    String fileName = defaultFileName,
  }) {
    return JsonFileLocalControlOverlayStore._(
      directoryProvider: directoryProvider ?? getApplicationSupportDirectory,
      fileName: fileName,
    );
  }

  const JsonFileLocalControlOverlayStore._({
    required Future<Directory> Function() directoryProvider,
    required String fileName,
  })  : _directoryProvider = directoryProvider,
        _fileName = fileName;

  static const String defaultFileName = 'local_control_overlays.json';

  final Future<Directory> Function() _directoryProvider;
  final String _fileName;

  @override
  Future<List<LocalControlDecision>> list() async {
    try {
      final file = await _dataFile(createDirectory: false);
      final raw = await AtomicJsonFileWriter.read(file);
      if (raw == null) {
        return const <LocalControlDecision>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <LocalControlDecision>[];
      }

      final decisions = decoded
          .whereType<Map>()
          .map(
            (item) => LocalControlDecision.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(growable: false)
        ..sort((left, right) => left.targetKey.compareTo(right.targetKey));

      return decisions;
    } on MissingPluginException {
      return const <LocalControlDecision>[];
    } on MissingPlatformDirectoryException {
      return const <LocalControlDecision>[];
    } on FileSystemException {
      return const <LocalControlDecision>[];
    } on FormatException {
      return const <LocalControlDecision>[];
    } on TypeError {
      return const <LocalControlDecision>[];
    }
  }

  @override
  Future<void> save(LocalControlDecision decision) async {
    try {
      final existing = await list();
      final next = <String, LocalControlDecision>{
        for (final item in existing) item.targetKey: item,
        decision.targetKey: decision,
      }.values.toList(growable: false)
        ..sort((left, right) => left.targetKey.compareTo(right.targetKey));

      final file = await _dataFile(createDirectory: true);
      final payload = next.map((item) => item.toJson()).toList(growable: false);
      await AtomicJsonFileWriter.write(file, jsonEncode(payload));
    } on MissingPluginException {
      return;
    } on MissingPlatformDirectoryException {
      return;
    } on FileSystemException {
      return;
    }
  }

  @override
  Future<bool> remove(String targetKey) async {
    try {
      final existing = await list();
      final next = existing
          .where((item) => item.targetKey != targetKey)
          .toList(growable: false);
      if (next.length == existing.length) {
        return false;
      }

      final file = await _dataFile(createDirectory: true);
      final payload = next.map((item) => item.toJson()).toList(growable: false);
      await AtomicJsonFileWriter.write(file, jsonEncode(payload));
      return true;
    } on MissingPluginException {
      return false;
    } on MissingPlatformDirectoryException {
      return false;
    } on FileSystemException {
      return false;
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
