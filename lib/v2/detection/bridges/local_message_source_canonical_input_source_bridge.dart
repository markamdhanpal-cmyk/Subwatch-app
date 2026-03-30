import '../../../domain/contracts/local_message_source.dart';
import '../contracts/canonical_input_source.dart';
import '../mappers/message_record_canonical_input_mapper.dart';
import '../models/canonical_input.dart';

class LocalMessageSourceCanonicalInputSourceBridge
    implements CanonicalInputSource {
  LocalMessageSourceCanonicalInputSourceBridge({
    required LocalMessageSource messageSource,
    CanonicalInputOrigin origin =
        const CanonicalInputOrigin.legacyMessageRecordBridge(),
    MessageRecordCanonicalInputMapper? mapper,
  })  : _messageSource = messageSource,
        _origin = origin,
        _mapper = mapper ?? const MessageRecordCanonicalInputMapper();

  final LocalMessageSource _messageSource;
  final CanonicalInputOrigin _origin;
  final MessageRecordCanonicalInputMapper _mapper;

  @override
  Future<List<CanonicalInput>> loadCanonicalInputs() async {
    final messages = await _messageSource.loadMessages();

    return List<CanonicalInput>.unmodifiable(
      messages.map(
        (message) => _mapper.map(
          message,
          origin: _origin,
        ),
      ),
    );
  }
}
