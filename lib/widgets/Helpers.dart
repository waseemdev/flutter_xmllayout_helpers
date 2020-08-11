import 'dart:io';
import 'package:flutter/widgets.dart';

class WidgetHelpers {
  static List<T> mapToWidgetList<T extends Widget, D>(
      Iterable<dynamic> items, T Function(D item, int index) map) {
    List<T> result = [];
    for (var index = 0; index < items.length; index++) {
      result.add(map(items.elementAt(index), index));
    }
    return result;
  }

  static Widget ifTrue(bool condition, Widget Function() trueWidget,
      Widget Function() falseWidget) {
    if (condition != null && condition) {
      return trueWidget();
    }
    return falseWidget();
  }

  static Widget ifElseChain(
      Iterable<SwitchCase> ifElseChains, Widget Function() elseBuilder) {
    final trueItem = ifElseChains.firstWhere(
        (a) => a.value != null && a.value == true,
        orElse: () => null);
    return trueItem != null
        ? trueItem.builder()
        : (elseBuilder != null
            ? elseBuilder()
            : null // Container(height: 0, width: 0)
            );
  }

  static List<Widget> ifElseChainMultiChild(
      Iterable<SwitchCaseMultiChild> ifElseChains,
      Iterable<Widget> Function() elseBuilder) {
    final trueItem = ifElseChains.firstWhere(
        (a) => a.value != null && a.value == true,
        orElse: () => null);
    return trueItem != null
        ? trueItem.builder()
        : (elseBuilder != null
            ? elseBuilder()
            : [/*Container(height: 0, width: 0)*/]);
  }

  static Widget switchValue(dynamic value,
      Widget Function() defaultWidgetBuilder, Iterable<SwitchCase> cases) {
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

    if (platformResult &&
        (version == null || version.isEmpty || version == Platform.version)) {
      return widget;
    }
    return defaultWidget;
  }

  static dynamic onPlatformProperty(
      {dynamic Function() ios,
      dynamic Function() android,
      dynamic Function() windows,
      dynamic Function() mac,
      dynamic Function() linux}) {
    if (Platform.isAndroid) {
      return android();
    } else if (Platform.isIOS) {
      return ios();
    } else if (Platform.isAndroid) {
      return android();
    } else if (Platform.isWindows) {
      return windows();
    } else if (Platform.isMacOS) {
      return mac();
    } else if (Platform.isLinux) {
      return linux();
    }

    return null;
  }

  static Widget onPlatformWidget(
      {Widget Function() ios,
      Widget Function() android,
      Widget Function() windows,
      Widget Function() mac,
      Widget Function() linux}) {
    if (Platform.isAndroid) {
      return android();
    } else if (Platform.isIOS) {
      return ios();
    } else if (Platform.isAndroid) {
      return android();
    } else if (Platform.isWindows) {
      return windows();
    } else if (Platform.isMacOS) {
      return mac();
    } else if (Platform.isLinux) {
      return linux();
    }

    return Container(width: 0, height: 0);
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
