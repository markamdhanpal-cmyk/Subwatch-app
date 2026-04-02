import 'dart:io';

Future<Directory> createWorkspaceTempDirectory(String prefix) async {
  final root = Directory(
    '${Directory.current.path}${Platform.pathSeparator}tmp${Platform.pathSeparator}test_sandbox',
  );
  if (!await root.exists()) {
    await root.create(recursive: true);
  }

  final sanitizedPrefix = prefix.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  final directory = Directory(
    '${root.path}${Platform.pathSeparator}${sanitizedPrefix}_${DateTime.now().microsecondsSinceEpoch}',
  );
  await directory.create(recursive: true);
  return directory;
}

