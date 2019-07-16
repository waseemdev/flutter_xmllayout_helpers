
import 'dart:io';
import 'package:flutter/widgets.dart';

class WidgetHelpers {

  static List<Widget> mapToWidgetList(List<dynamic> items, Widget Function(dynamic item, int index) map) {
    List<Widget> result = [];
    for (var index = 0; index < items.length; index++) {
      result.add(map(items[index], index));
    }
    return result;
  }

  static Widget ifTrue(bool condition, Widget Function() trueWidget, Widget Function() falseWidget) {
    if (condition) {
      return trueWidget();
    }
    return falseWidget();
  }

  static Widget ifElseChain(List<SwitchCase> ifElseChains, Widget Function() elseBuilder) {
    final trueItem = ifElseChains.firstWhere((a) => a.value != null && a.value == true, orElse: () => null);
    return trueItem != null ? trueItem.builder() : (elseBuilder != null ? elseBuilder() : Container(height: 0, width: 0));
  }

  static List<Widget> ifElseChainMultiChild(List<SwitchCaseMultiChild> ifElseChains, List<Widget> Function() elseBuilder) {
    final trueItem = ifElseChains.firstWhere((a) => a.value != null && a.value == true, orElse: () => null);
    return trueItem != null ? trueItem.builder() : (elseBuilder != null ? elseBuilder() : [Container(height: 0, width: 0)]);
  }

  static Widget switchValue(dynamic value, Widget Function() defaultWidgetBuilder, List<SwitchCase> cases) {
    final res = cases.firstWhere((a) => a.value == value, orElse: () => null);
    return res != null ? res.builder() : defaultWidgetBuilder;
  }

  static Widget when(String value, Widget widget, Widget defaultWidget) {
    final segments = value.split(':');
    final platform = segments.length > 0 ? segments[0] : value;
    final version = segments.length > 1 ? segments[1] : '';
    final platformResult = platform == 'android' && Platform.isAndroid ||
        platform == 'ios' && Platform.isIOS ||
        platform == 'windows' && Platform.isWindows ||
        platform == 'mac' && Platform.isMacOS ||
        platform == 'linux' && Platform.isLinux;
    
    if (platformResult && (version == Platform.version || version == null || version.isEmpty)) {
      return widget;
    }
    return defaultWidget;
  }
}

class SwitchCase {
  SwitchCase(this.value, this.builder);
  dynamic value;
  Widget Function() builder;
}

class SwitchCaseMultiChild {
  SwitchCaseMultiChild(this.value, this.builder);
  dynamic value;
  List<Widget> Function() builder;
}

