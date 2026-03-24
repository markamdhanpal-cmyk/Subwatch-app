import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../contracts/local_service_presentation_overlay_store.dart';
import '../models/local_service_presentation_overlay_models.dart';

class JsonFileLocalServicePresentationOverlayStore
    implements LocalServicePresentationOverlayStore {
  factory JsonFileLocalServicePresentationOverlayStore.applicationSupport({
    Future<Directory> Function()? directoryProvider,
    String fileName = defaultFileName,
  }) {
    return JsonFileLocalServicePresentationOverlayStore._(
      directoryProvider: directoryProvider ?? getApplicationSupportDirectory,
      fileName: fileName,
    );
  }

  const JsonFileLocalServicePresentationOverlayStore._({
    required Future<Directory> Function() directoryProvider,
    required String fileName,
  })  : _directoryProvider = directoryProvider,
        _fileName = fileName;

  static const String defaultFileName =
      'local_service_presentation_overlays.json';

  final Future<Directory> Function() _directoryProvider;
  final String _fileName;

  @override
  Future<List<LocalServicePresentationOverlay>> list() async {
    try {
      final file = await _dataFile(createDirectory: false);
      if (!await file.exists()) {
        return const <LocalServicePresentationOverlay>[];
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const <LocalServicePresentationOverlay>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <LocalServicePresentationOverlay>[];
      }

      final overlays = decoded
          .whereType<Map>()
          .map(
            (item) => LocalServicePresentationOverlay.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(growable: false)
        ..sort((left, right) => left.serviceKey.compareTo(right.serviceKey));

      return overlays;
    } on MissingPluginException {
      return const <LocalServicePresentationOverlay>[];
    } on MissingPlatformDirectoryException {
      return const <LocalServicePresentationOverlay>[];
    } on FileSystemException {
      return const <LocalServicePresentationOverlay>[];
    } on FormatException {
      return const <LocalServicePresentationOverlay>[];
    } on TypeError {
      return const <LocalServicePresentationOverlay>[];
    }
  }

  @override
  Future<void> save(LocalServicePresentationOverlay overlay) async {
    try {
      final existing = await list();
      final next = <String, LocalServicePresentationOverlay>{
        for (final item in existing) item.serviceKey: item,
        overlay.serviceKey: overlay,
      }.values.toList(growable: false)
        ..sort((left, right) => left.serviceKey.compareTo(right.serviceKey));

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
