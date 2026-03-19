class MessageRecord {
  const MessageRecord({
    required this.id,
    required this.sourceAddress,
    required this.body,
    required this.receivedAt,
  });

  final String id;
  final String sourceAddress;
  final String body;
  final DateTime receivedAt;
}
