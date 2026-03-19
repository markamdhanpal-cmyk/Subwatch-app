class EvidenceTrail {
  EvidenceTrail({
    List<String> messageIds = const <String>[],
    List<String> eventIds = const <String>[],
    List<String> notes = const <String>[],
  })  : messageIds = List.unmodifiable(messageIds),
        eventIds = List.unmodifiable(eventIds),
        notes = List.unmodifiable(notes);

  final List<String> messageIds;
  final List<String> eventIds;
  final List<String> notes;

  EvidenceTrail copyWith({
    List<String>? messageIds,
    List<String>? eventIds,
    List<String>? notes,
  }) {
    return EvidenceTrail(
      messageIds: messageIds ?? this.messageIds,
      eventIds: eventIds ?? this.eventIds,
      notes: notes ?? this.notes,
    );
  }

  static EvidenceTrail empty() => EvidenceTrail();
}
