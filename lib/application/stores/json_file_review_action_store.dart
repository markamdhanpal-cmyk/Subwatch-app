import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../contracts/review_action_store.dart';
import '../models/review_item_action_models.dart';

class JsonFileReviewActionStore implements ReviewActionStore {
  factory JsonFileReviewActionStore.applicationSupport({
    Future<Directory> Function()? directoryProvider,
    String fileName = defaultFileName,
  }) {
    return JsonFileReviewActionStore._(
      directoryProvider: directoryProvider ?? getApplicationSupportDirectory,
      fileName: fileName,
    );
  }

  const JsonFileReviewActionStore._({
    required Future<Directory> Function() directoryProvider,
    required String fileName,
  })  : _directoryProvider = directoryProvider,
        _fileName = fileName;

  static const String defaultFileName = 'review_actions.json';

  final Future<Directory> Function() _directoryProvider;
  final String _fileName;

  @override
  Future<List<ReviewItemDecision>> list() async {
    try {
      final file = await _dataFile(createDirectory: false);
      if (!await file.exists()) {
        return const <ReviewItemDecision>[];
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const <ReviewItemDecision>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <ReviewItemDecision>[];
      }

      final decisions = decoded
          .whereType<Map>()
          .map(
            (item) => ReviewItemDecision.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(growable: false)
        ..sort((left, right) => left.targetKey.compareTo(right.targetKey));

      return decisions;
    } on MissingPluginException {
      return const <ReviewItemDecision>[];
    } on MissingPlatformDirectoryException {
      return const <ReviewItemDecision>[];
    } on FileSystemException {
      return const <ReviewItemDecision>[];
    } on FormatException {
      return const <ReviewItemDecision>[];
    } on TypeError {
      return const <ReviewItemDecision>[];
    }
  }

  @override
  Future<void> save(ReviewItemDecision decision) async {
    try {
      final existing = await list();
      final next = <String, ReviewItemDecision>{
        for (final item in existing) item.targetKey: item,
        decision.targetKey: decision,
      }.values.toList(growable: false)
        ..sort((left, right) => left.targetKey.compareTo(right.targetKey));

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
