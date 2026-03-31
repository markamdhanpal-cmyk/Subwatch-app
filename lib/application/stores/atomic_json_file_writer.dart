import 'dart:io';

class AtomicJsonFileWriter {
  const AtomicJsonFileWriter._();

  static Future<void> write(File targetFile, String payload) async {
    final tempFile = File('${targetFile.path}.tmp');
    await tempFile.writeAsString(payload, flush: true);

    if (Platform.isWindows && await targetFile.exists()) {
      await targetFile.delete();
    }
    await tempFile.rename(targetFile.path);
  }

  static Future<String?> read(File targetFile) async {
    final tempFile = File('${targetFile.path}.tmp');
    if (await tempFile.exists()) {
      if (!await targetFile.exists()) {
        try {
          // Crash occurred between delete and rename on Windows, or similar
          await tempFile.rename(targetFile.path);
        } catch (_) {}
      } else {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }

    if (!await targetFile.exists()) {
      return null;
    }

    final raw = await targetFile.readAsString();
    if (raw.trim().isEmpty) {
      return null;
    }

    return raw;
  }
}
