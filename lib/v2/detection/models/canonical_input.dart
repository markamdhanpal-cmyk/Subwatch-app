enum CanonicalInputKind {
  sms,
  mms,
  rcs,
  receipt,
  appStore,
  bankTransaction,
  manual,
  csv,
}

enum CanonicalInputOriginKind {
  deviceSmsInbox,
  deviceMmsInbox,
  deviceRcsInbox,
  emailReceiptImport,
  googlePlayRecord,
  appleAppStoreRecord,
  bankConnectorSync,
  sampleSeedData,
  manualEntry,
  manualReceiptEntry,
  csvImport,
  legacyMessageRecordBridge,
}

enum CanonicalInputCaptureConfidence {
  high,
  medium,
  low,
}

class CanonicalInputOrigin {
  const CanonicalInputOrigin({
    required this.kind,
    required this.sourceLabel,
    required this.localOnly,
    this.batchId,
    this.captureConfidence = CanonicalInputCaptureConfidence.medium,
  });

  const CanonicalInputOrigin.deviceSmsInbox()
      : kind = CanonicalInputOriginKind.deviceSmsInbox,
        sourceLabel = 'device_sms_inbox',
        localOnly = true,
        batchId = null,
        captureConfidence = CanonicalInputCaptureConfidence.high;

  const CanonicalInputOrigin.sampleSeedData()
      : kind = CanonicalInputOriginKind.sampleSeedData,
        sourceLabel = 'sample_seed_data',
        localOnly = true,
        batchId = null,
        captureConfidence = CanonicalInputCaptureConfidence.medium;

  const CanonicalInputOrigin.manualEntry()
      : kind = CanonicalInputOriginKind.manualEntry,
        sourceLabel = 'manual_entry',
        localOnly = true,
        batchId = null,
        captureConfidence = CanonicalInputCaptureConfidence.medium;

  const CanonicalInputOrigin.manualReceiptEntry({
    CanonicalInputCaptureConfidence captureConfidence =
        CanonicalInputCaptureConfidence.medium,
  })  : kind = CanonicalInputOriginKind.manualReceiptEntry,
        sourceLabel = 'manual_receipt_entry',
        localOnly = true,
        batchId = null,
        captureConfidence = captureConfidence;

  const CanonicalInputOrigin.legacyMessageRecordBridge()
      : kind = CanonicalInputOriginKind.legacyMessageRecordBridge,
        sourceLabel = 'legacy_message_record_bridge',
        localOnly = true,
        batchId = null,
        captureConfidence = CanonicalInputCaptureConfidence.medium;

  factory CanonicalInputOrigin.csvImport({
    required String batchId,
    CanonicalInputCaptureConfidence captureConfidence =
        CanonicalInputCaptureConfidence.medium,
  }) {
    return CanonicalInputOrigin(
      kind: CanonicalInputOriginKind.csvImport,
      sourceLabel: 'csv_import',
      localOnly: true,
      batchId: batchId,
      captureConfidence: captureConfidence,
    );
  }

  factory CanonicalInputOrigin.emailReceiptImport({
    String? batchId,
    CanonicalInputCaptureConfidence captureConfidence =
        CanonicalInputCaptureConfidence.medium,
  }) {
    return CanonicalInputOrigin(
      kind: CanonicalInputOriginKind.emailReceiptImport,
      sourceLabel: 'email_receipt_import',
      localOnly: true,
      batchId: batchId,
      captureConfidence: captureConfidence,
    );
  }

  factory CanonicalInputOrigin.googlePlayRecord({
    String? batchId,
    CanonicalInputCaptureConfidence captureConfidence =
        CanonicalInputCaptureConfidence.high,
  }) {
    return CanonicalInputOrigin(
      kind: CanonicalInputOriginKind.googlePlayRecord,
      sourceLabel: 'google_play_record',
      localOnly: true,
      batchId: batchId,
      captureConfidence: captureConfidence,
    );
  }

  factory CanonicalInputOrigin.appleAppStoreRecord({
    String? batchId,
    CanonicalInputCaptureConfidence captureConfidence =
        CanonicalInputCaptureConfidence.high,
  }) {
    return CanonicalInputOrigin(
      kind: CanonicalInputOriginKind.appleAppStoreRecord,
      sourceLabel: 'apple_app_store_record',
      localOnly: true,
      batchId: batchId,
      captureConfidence: captureConfidence,
    );
  }

  factory CanonicalInputOrigin.bankConnectorSync({
    required String connectorId,
    String? batchId,
    CanonicalInputCaptureConfidence captureConfidence =
        CanonicalInputCaptureConfidence.high,
  }) {
    return CanonicalInputOrigin(
      kind: CanonicalInputOriginKind.bankConnectorSync,
      sourceLabel: connectorId,
      localOnly: true,
      batchId: batchId,
      captureConfidence: captureConfidence,
    );
  }

  final CanonicalInputOriginKind kind;
  final String sourceLabel;
  final bool localOnly;
  final String? batchId;
  final CanonicalInputCaptureConfidence captureConfidence;
}

class CanonicalInput {
  CanonicalInput({
    required this.id,
    required this.kind,
    required this.origin,
    required this.receivedAt,
    required this.textBody,
    this.senderHandle,
    this.subject,
    this.threadId,
    this.attachmentCount = 0,
    List<String> richTextSegments = const <String>[],
  })  : assert(attachmentCount >= 0),
        richTextSegments = List.unmodifiable(richTextSegments);

  factory CanonicalInput.deviceSms({
    required String id,
    required String senderHandle,
    required String textBody,
    required DateTime receivedAt,
    String? threadId,
    List<String> richTextSegments = const <String>[],
  }) {
    return CanonicalInput(
      id: id,
      kind: CanonicalInputKind.sms,
      origin: const CanonicalInputOrigin.deviceSmsInbox(),
      receivedAt: receivedAt,
      senderHandle: senderHandle,
      textBody: textBody,
      threadId: threadId,
      richTextSegments: richTextSegments,
    );
  }

  factory CanonicalInput.sampleSms({
    required String id,
    required String senderHandle,
    required String textBody,
    required DateTime receivedAt,
    String? threadId,
    List<String> richTextSegments = const <String>[],
  }) {
    return CanonicalInput(
      id: id,
      kind: CanonicalInputKind.sms,
      origin: const CanonicalInputOrigin.sampleSeedData(),
      receivedAt: receivedAt,
      senderHandle: senderHandle,
      textBody: textBody,
      threadId: threadId,
      richTextSegments: richTextSegments,
    );
  }

  factory CanonicalInput.manualText({
    required String id,
    required String textBody,
    required DateTime receivedAt,
    String? senderHandle,
    List<String> richTextSegments = const <String>[],
  }) {
    return CanonicalInput(
      id: id,
      kind: CanonicalInputKind.manual,
      origin: const CanonicalInputOrigin.manualEntry(),
      receivedAt: receivedAt,
      senderHandle: senderHandle,
      textBody: textBody,
      richTextSegments: richTextSegments,
    );
  }

  factory CanonicalInput.csvText({
    required String id,
    required String textBody,
    required DateTime receivedAt,
    required String batchId,
    String? senderHandle,
    List<String> richTextSegments = const <String>[],
  }) {
    return CanonicalInput(
      id: id,
      kind: CanonicalInputKind.csv,
      origin: CanonicalInputOrigin.csvImport(batchId: batchId),
      receivedAt: receivedAt,
      senderHandle: senderHandle,
      textBody: textBody,
      richTextSegments: richTextSegments,
    );
  }

  final String id;
  final CanonicalInputKind kind;
  final CanonicalInputOrigin origin;
  final DateTime receivedAt;
  final String textBody;
  final String? senderHandle;
  final String? subject;
  final String? threadId;
  final int attachmentCount;
  final List<String> richTextSegments;
}
