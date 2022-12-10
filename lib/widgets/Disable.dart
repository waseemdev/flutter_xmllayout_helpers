import 'package:flutter/widgets.dart';

typedef DisableWidgetBuilder = Widget Function(BuildContext context, Function? event);

class Disable extends StatelessWidget {
  final DisableWidgetBuilder builder;
  final Function? event;
  final value;
  Disable({this.value, required this.builder, this.event});

  @override
  Widget build(BuildContext context) {
    return builder(context, value == true ? null : event);
  }
}
