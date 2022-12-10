import 'package:flutter/widgets.dart';
import 'package:flutter_xmllayout_helpers/pipes/PrecentPipes.dart';
import '../pipes/Pipe.dart';

class PipeProvider {
  Map<String, Pipe> _pipes = new Map<String, Pipe>();

  PipeProvider() {
    _registerBuiltInProviders();
  }

  void _registerBuiltInProviders() {
    register(new WidthPercentPipe());
    register(new HeightPercentPipe());
  }

  void register(Pipe pipe, {String? name}) {
    if (name == null || name.isEmpty) {
      name = pipe.name;
    }
    if (!_pipes.containsKey(name)) {
      _pipes.addEntries([new MapEntry(name, pipe)]);
    }
  }

  dynamic transform(
      BuildContext context, String name, dynamic value, List<dynamic> args) {
    if (!_pipes.containsKey(name)) {
      throw new Exception('No such a pipe with name: "$name"');
    }

    return _pipes[name]!.transform(context, value, args);
  }
}
