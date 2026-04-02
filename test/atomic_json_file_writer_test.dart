import 'dart:io';

import 'support/test_temp_dir.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/stores/atomic_json_file_writer.dart';

void main() {
  group('AtomicJsonFileWriter', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await createWorkspaceTempDirectory('atomic_write_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('writes and reads string payload safely via temp file', () async {
      final file = File('${tempDir.path}/test.json');
      await AtomicJsonFileWriter.write(file, '{"test":true}');

      final read = await AtomicJsonFileWriter.read(file);
      expect(read, '{"test":true}');

      // The temp file shouldn't exist
      final tempFile = File('${file.path}.tmp');
      expect(await tempFile.exists(), isFalse);
    });

    test('survives leftover temp files gracefully (simulated crash)', () async {
      final file = File('${tempDir.path}/test2.json');
      await AtomicJsonFileWriter.write(file, '{"valid":true}');

      // Simulate a crashed future write that left a tmp file
      final tempFile = File('${file.path}.tmp');
      await tempFile.writeAsString('{"partial":', flush: true);

      final read = await AtomicJsonFileWriter.read(file);
      // Valid data should be retrieved
      expect(read, '{"valid":true}');
      
      // Leftover temp file should be cleaned up by the read process
      expect(await tempFile.exists(), isFalse);
    });

    test('returns null if no data exists', () async {
      final file = File('${tempDir.path}/test3.json');
      final read = await AtomicJsonFileWriter.read(file);

      expect(read, isNull);
    });

    test('recovers from failed rename (missing target, exists tmp)', () async {
      final file = File('${tempDir.path}/test4.json');
      final tempFile = File('${file.path}.tmp');
      await tempFile.writeAsString('{"recovered":true}', flush: true);

      final read = await AtomicJsonFileWriter.read(file);
      expect(read, '{"recovered":true}');
      
      expect(await file.exists(), isTrue);
      expect(await tempFile.exists(), isFalse);
    });
  });
}

