import '../../domain/entities/message_record.dart';
import '../../domain/entities/subscription_event.dart';
import 'event_pipeline_use_case.dart';
import 'resolver_pipeline_use_case.dart';

class IngestionUseCase {
  const IngestionUseCase({
    required EventPipelineUseCase eventPipeline,
    required ResolverPipelineUseCase resolverPipeline,
  })  : _eventPipeline = eventPipeline,
        _resolverPipeline = resolverPipeline;

  final EventPipelineUseCase _eventPipeline;
  final ResolverPipelineUseCase _resolverPipeline;

  Future<List<SubscriptionEvent>> execute(List<MessageRecord> messages) async {
    final events = _eventPipeline.execute(messages);
    await _resolverPipeline.execute(events);
    return events;
  }
}
