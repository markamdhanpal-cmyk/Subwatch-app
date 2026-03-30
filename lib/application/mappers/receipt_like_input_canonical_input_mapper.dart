import '../../v2/detection/models/canonical_input.dart';
import '../models/receipt_adapter_models.dart';

class ReceiptLikeInputCanonicalInputMapper {
  const ReceiptLikeInputCanonicalInputMapper();

  CanonicalInput map(ReceiptLikeInputRecord record) {
    final origin = switch (record.kind) {
      ReceiptLikeInputKind.emailReceipt => CanonicalInputOrigin.emailReceiptImport(
          batchId: record.batchId,
          captureConfidence: record.captureConfidence,
        ),
      ReceiptLikeInputKind.manualReceipt => CanonicalInputOrigin.manualReceiptEntry(
          captureConfidence: record.captureConfidence,
        ),
    };

    return CanonicalInput(
      id: record.id,
      kind: CanonicalInputKind.receipt,
      origin: origin,
      receivedAt: record.receivedAt,
      textBody: _composeTextBody(record),
      senderHandle: record.senderHandle ?? record.sourceLabel,
      subject: record.subject,
      threadId: record.batchId,
      attachmentCount: record.attachmentCount,
      richTextSegments: <String>[
        if (record.sourceLabel != null) 'Source: ${record.sourceLabel}',
        if (record.serviceHint != null) 'Service hint: ${record.serviceHint}',
        if (record.receiptReference != null)
          'Receipt reference: ${record.receiptReference}',
        ...record.extractedTextSegments,
      ],
    );
  }

  List<CanonicalInput> mapAll(Iterable<ReceiptLikeInputRecord> records) {
    return List<CanonicalInput>.unmodifiable(records.map(map));
  }

  String _composeTextBody(ReceiptLikeInputRecord record) {
    final segments = <String>[
      switch (record.kind) {
        ReceiptLikeInputKind.emailReceipt => 'Email receipt',
        ReceiptLikeInputKind.manualReceipt => 'Manual receipt record',
      },
      if (record.subject.trim().isNotEmpty) 'Subject: ${record.subject.trim()}.',
      if (record.serviceHint != null) 'Service hint: ${record.serviceHint}.',
      record.body.trim(),
      if (record.receiptReference != null)
        'Receipt reference: ${record.receiptReference}.',
    ];

    return segments.join(' ');
  }
}
