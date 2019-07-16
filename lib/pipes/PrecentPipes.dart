import 'package:flutter/widgets.dart';
import 'package:flutter_xmllayout_helpers/pipes/Pipe.dart';

class WidthPercentPipe extends Pipe {
  String get name => 'widthPercent';

  dynamic transform(BuildContext context, dynamic value, List<dynamic> args) {
    final size = MediaQuery.of(context).size;
    return (size.width * value) / 100.0;
  }
}

class HeightPercentPipe extends Pipe {
  String get name => 'heightPercent';

  dynamic transform(BuildContext context, dynamic value, List<dynamic> args) {
    final size = MediaQuery.of(context).size;
    return (size.height * value) / 100.0;
  }
}