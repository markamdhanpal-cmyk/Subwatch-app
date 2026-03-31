import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'app/subscription_killer_app.dart';

void main() {
  enableFlutterDriverExtension();
  runApp(const SubKillerApp());
}
