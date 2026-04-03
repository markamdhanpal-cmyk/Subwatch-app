import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../contracts/service_evidence_bucket_store.dart';
import '../models/persisted_service_evidence_bucket.dart';
import '../../domain/entities/service_evidence_bucket.dart';
import 'atomic_json_file_writer.dart';

class JsonFileServiceEvidenceBucketStore implements ServiceEvidenceBucketStore {
  factory JsonFileServiceEvidenceBucketStore.applicationSupport({
    Future<Directory> Function()? directoryProvider,
    String fileName = defaultFileName,
  }) {
    return JsonFileServiceEvidenceBucketStore._(
      directoryProvider: directoryProvider ?? getApplicationSupportDirectory,
      fileName: fileName,
    );
  }

  const JsonFileServiceEvidenceBucketStore._({
    required Future<Directory> Function() directoryProvider,
    required String fileName,
  })  : _directoryProvider = directoryProvider,
        _fileName = fileName;

  static const String defaultFileName = 'service_evidence_buckets.json';
  static const int schemaVersion = 3;

  final Future<Directory> Function() _directoryProvider;
  final String _fileName;

  @override
  Future<List<ServiceEvidenceBucket>> load() async {
    try {
      final file = await _dataFile(createDirectory: false);
      final raw = await AtomicJsonFileWriter.read(file);
      if (raw == null) {
        return const <ServiceEvidenceBucket>[];
      }

      final decoded = jsonDecode(raw);
      final rawBuckets = _extractBucketList(decoded);
      if (rawBuckets == null) {
        return const <ServiceEvidenceBucket>[];
      }

      final parsedBuckets = <ServiceEvidenceBucket>[];
      for (final item in rawBuckets.whereType<Map>()) {
        try {
          parsedBuckets.add(
            PersistedServiceEvidenceBucket.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ).toDomain(),
          );
        } on FormatException {
          continue;
        } on TypeError {
          continue;
        }
      }

      final buckets = _sanitizeBucketsForPersistence(parsedBuckets);

      return buckets;
    } on MissingPluginException {
      return const <ServiceEvidenceBucket>[];
    } on MissingPlatformDirectoryException {
      return const <ServiceEvidenceBucket>[];
    } on FileSystemException {
      return const <ServiceEvidenceBucket>[];
    } on FormatException {
      return const <ServiceEvidenceBucket>[];
    } on TypeError {
      return const <ServiceEvidenceBucket>[];
    }
  }

  @override
  Future<void> save(List<ServiceEvidenceBucket> buckets) async {
    try {
      final file = await _dataFile(createDirectory: true);
      final payload = _sanitizeBucketsForPersistence(buckets);
      await AtomicJsonFileWriter.write(
          file,
          jsonEncode(
            <String, Object?>{
              'schemaVersion': schemaVersion,
              'savedAt': DateTime.now().toIso8601String(),
              'buckets': payload
                  .map(
                    (bucket) =>
                        PersistedServiceEvidenceBucket.fromDomain(bucket)
                            .toJson(),
                  )
                  .toList(growable: false),
            },
          ));
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

  List<dynamic>? _extractBucketList(Object? decoded) {
    if (decoded is List) {
      return decoded;
    }
    if (decoded is! Map) {
      return null;
    }

    final buckets = decoded['buckets'];
    if (buckets is List) {
      return buckets;
    }

    return null;
  }

  List<ServiceEvidenceBucket> _sanitizeBucketsForPersistence(
    Iterable<ServiceEvidenceBucket> buckets,
  ) {
    final deduped = <String, ServiceEvidenceBucket>{};
    for (final bucket in buckets) {
      final key = bucket.serviceKey.value;
      if (key.isEmpty) {
        continue;
      }

      final existing = deduped[key];
      if (existing == null || bucket.lastSeenAt.isAfter(existing.lastSeenAt)) {
        deduped[key] = bucket;
      }
    }

    final sanitized = deduped.values.toList(growable: false)
      ..sort(
        (left, right) =>
            left.serviceKey.value.compareTo(right.serviceKey.value),
      );
    return List<ServiceEvidenceBucket>.unmodifiable(sanitized);
  }
}
