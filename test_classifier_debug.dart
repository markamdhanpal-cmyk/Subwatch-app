
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/domain/classifiers/weak_signal_review_classifier.dart';
import 'package:sub_killer/domain/classifiers/subscription_billed_classifier.dart';
import 'package:sub_killer/domain/classifiers/telecom_bundle_classifier.dart';
import 'package:sub_killer/domain/entities/message_record.dart';

void main() {
  final message = MessageRecord(
    id: '1',
    sourceAddress: 'AD-JIOHTT',
    body: 'Your Jiohotstar subscription may renew shortly.',
    receivedAt: DateTime.now(),
  );

  final weak = const WeakSignalReviewClassifier().classify(message);
  print('WeakSignalReviewClassifier: ${weak?.eventType} fragments: ${weak?.evidenceFragments.map((f) => f.type).toList()}');

  final billed = const SubscriptionBilledClassifier().classify(message);
  print('SubscriptionBilledClassifier: ${billed?.eventType}');

  final telecom = const TelecomBundleClassifier().classify(message);
  print('TelecomBundleClassifier: ${telecom?.eventType}');
}
