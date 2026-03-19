class RawDeviceSms {
  const RawDeviceSms({
    required this.id,
    required this.address,
    required this.body,
    required this.receivedAt,
  });

  final String id;
  final String address;
  final String body;
  final DateTime receivedAt;
}
