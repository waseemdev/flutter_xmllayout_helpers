
import 'package:flutter/widgets.dart';

abstract class Pipe {
  String get name;
  dynamic transform(BuildContext context, dynamic value, List<dynamic> args);
}