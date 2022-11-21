import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

// class AnimationControllerAccessor {
//   BehaviorSubject _subject = BehaviorSubject();
//   bool _initialized = false;

//   Future<AnimationController> getAnimationController() async {
//     AnimationController controller;
//     _subject.take(1).listen((data) => controller = data);
//     final streamQueue = new StreamQueue(_subject);
//     await Future.wait([streamQueue.next]);
//     return controller;
//   }
// }

// original source: https://github.com/GIfatahTH/animator/blob/master/lib/animator.dart

class AnimationBuilder extends StatefulWidget {
  AnimationBuilder(
      {Key? key,
      this.controller,
      this.animation,
      this.child,
      this.tween,
      this.duration,
      this.curve: Curves.linear,
      this.cycles,
      int? repeats,
      this.builder,
      this.builderMap,
      this.tweenMap,
      this.name,
      this.autoTrigger,
      this.customListener,
      this.endAnimationListener,
      this.statusListener})
      : assert(() {
          if (builder == null && builderMap == null) {
            throw FlutterError('You have to define one of the "builder" or "builderMap" argument\n'
                ' - Define the "builder" argument if you have one Tween\n'
                ' - Define the "builderMap" argument if you have many Tweens');
          }
          if (builder != null && builderMap != null) {
            throw FlutterError('You have to define either builder or "builderMap" argument. you can\'t define both\n'
                ' - Define the "builder" argument if you have one Tween\n'
                ' - Define the "builderMap" argument if you have many Tweens');
          }
          if (builderMap != null && tweenMap == null) {
            throw FlutterError('"tweenMap" must not be null. If you have one tween use "builder" argument instead');
          }
          return true;
        }()),
        repeats = repeats ?? 0,
        super(
          key: key ?? UniqueKey(),
        );

  final Widget? child;

  final AnimationController? controller;
  final Animation<double>? animation;

  ///A linear interpolation between a beginning and ending value.
  ///
  ///`tween` argument is used for one Tween animation.
  final Tween? tween;

  ///A span of time, such as 27 days, 4 hours, 12 minutes, and 3 seconds
  final Duration? duration;

  ///An easing curve, i.e. a mapping of the unit interval to the unit interval.
  final Curve curve;

  ///The number of forward and backward periods the animation performs before stopping
  final int? cycles;

  ///The number of forward periods the animation performs before stopping
  final int repeats;

  ///Whether to start the animation when the AnimationBuilder widget
  ///is inserted into the tree.
  final bool? autoTrigger;

  ///Function to be called every time the animation value changes.
  ///
  ///The customListener is provided with an [Animation] object.
  final Function? customListener;

  ///VoidCallback to be called when animation is finished.
  final Function? endAnimationListener;

  ///Function to be called every time the status of the animation changes.
  ///
  ///The customListener is provided with an [AnimationStatus, AnimationSetup] object.
  final Function(AnimationStatus)? statusListener;

  ///The build strategy currently used for one Tween. AnimationBuilder widget rebuilds
  ///itself every time the animation changes value.
  ///
  ///The builder is provided with an [Animation] object.
  final Widget Function(Animation?, Widget? child)? builder;

  ///The build strategy currently used for multi-Tween. AnimationBuilder widget rebuilds
  ///itself every time the animation changes value.
  ///
  ///The `builderMap` is provided with an `Map<String, Animation>` object.
  final Widget Function(Map<String, Animation>, Widget? child)? builderMap;

  ///A linear interpolation between a beginning and ending value.
  ///
  ///`tweenMap` argument is used for multi-Tween animation.
  final Map<String, Tween<dynamic>>? tweenMap;

  ///The name of your AnimationBuilder widget.
  ///Many widgets can have the same name.
  ///
  ///It is used to rebuild this widget from your logic classes
  final dynamic name;

  @override
  AnimationBuilderState createState() => AnimationBuilderState();
}

class AnimationBuilderStateMixin {
  AnimationController? get controller => null;
  triggerAnimation({int? cycles, int? repeats, bool dispose = false, bool reset = false}) {}
}

class AnimationBuilderState extends State<AnimationBuilder> with TickerProviderStateMixin, AnimationBuilderStateMixin {
  AnimationController? _controller;
  AnimationController? get controller => _controller;
  Animation? _animation;
  // Map of animation, keys are the same as key of tweenMap
  Map<String, Animation> _animationMap = {};
  late Tween _tween;

  VoidCallback? _listener;
  Function(AnimationStatus)? _statusListener;
  Function(AnimationStatus)? _repeatStatusListener;
  Function()? _endAnimationListener;

  bool get _controllerIsDisposed => '$controller'.contains("DISPOSED");

  int? _cycles;
  int _repeats = 1;

  @override
  void initState() {
    _tween = widget.tween ?? Tween<double>(begin: 0, end: 1);
    _initAnimation(dispose: false, trigger: widget.autoTrigger, cycles: widget.cycles, repeats: widget.repeats);
    super.initState();
  }

  _initAnimation({bool? trigger = false, int? cycles, required int repeats, bool dispose = false}) {
    if (controller == null || _controllerIsDisposed) {
      _controller = widget.controller ?? AnimationController(duration: widget.duration, vsync: this);
    }
    _animation = _tween.animate(widget.animation ?? CurvedAnimation(parent: controller!, curve: widget.curve));

    if (widget.tweenMap != null) {
      _animationMap = {};
      widget.tweenMap?.forEach((k, v) {
        final anim = widget.animation ?? CurvedAnimation(parent: controller!, curve: widget.curve);
        _animationMap[k] = v.animate(anim);
      });
    }

    if (_listener != null) {
      _animation!.addListener(_listener!);
    }

    if (_statusListener != null) {
      _animation!.addStatusListener(_statusListener!);
    }

    if (cycles != null) {
      _cycles = cycles;
      _addCycleStatusListener(cycles, dispose, _endAnimationListener);
    } else {
      _repeats = repeats ?? 1;
      _addRepeatStatusListener(_repeats, dispose, _endAnimationListener);
    }

    if (trigger == true) {
      controller!.forward();
    }
  }

  /// Starts running this animation forwards (towards the end).
  triggerAnimation({int? cycles, int? repeats, bool dispose = false, bool reset = false}) {
    _initAnimation(repeats: repeats ?? _repeats, cycles: cycles ?? _cycles, dispose: dispose);

    if (reset && (cycles == null && _cycles == null)) {
      controller!.reset();
    }

    if (controller!.isDismissed) {
      controller!.forward();
    } else if (controller!.isCompleted && (cycles != null || _cycles != null)) {
      controller!.reverse();
    } else {
      controller!.reset();
      controller!.forward();
    }
  }

  _addCycleStatusListener(int cycles, bool dispose, Function? endAnimationListener) {
    if (_repeatStatusListener != null) {
      _animation!.removeStatusListener(_repeatStatusListener!);
    }
    if (cycles == 0) {
      _repeatStatusListener = (AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          controller!.reverse();
        }
        if (status == AnimationStatus.dismissed) {
          controller!.forward();
        }
      };
    } else {
      _repeatStatusListener = (AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          cycles--;
          if (cycles <= 0) {
            _animation!.removeStatusListener(_repeatStatusListener!);
            if (dispose) _disposeAnimation();
            if (endAnimationListener != null) endAnimationListener();
            return;
          } else {
            controller!.reverse();
          }
        }
        if (status == AnimationStatus.dismissed) {
          cycles--;
          if (cycles <= 0) {
            _animation!.removeStatusListener(_repeatStatusListener!);
            if (dispose) _disposeAnimation();
            if (endAnimationListener != null) endAnimationListener();
            return;
          } else {
            controller!.forward();
          }
        }
      };
    }
    _animation!.addStatusListener(_repeatStatusListener!);
  }

  /// Remove listener, statusListener and dispose the animation controller
  _disposeAnimation() {
    _animation!.removeListener(_listener!);
    _animation!.removeStatusListener(_statusListener!);

    if (!_controllerIsDisposed) {
      controller?.dispose();
    }
  }

  _addRepeatStatusListener(int repeats, bool dispose, Function? endAnimationListener) {
    if (_repeatStatusListener != null) {
      _animation!.removeStatusListener(_repeatStatusListener!);
    }
    if (repeats == 0) {
      _repeatStatusListener = (AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          controller!.reset();
          controller!.forward();
        }
      };
    } else {
      _repeatStatusListener = (AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          repeats--;
          if (repeats <= 0) {
            _animation!.removeStatusListener(_repeatStatusListener!);
            // if (dispose) disposeAnimation();

            if (endAnimationListener != null) {
              endAnimationListener();
            }
            return;
          } else {
            controller!.reset();
            controller!.forward();
          }
        }
      };
    }
    _animation!.addStatusListener(_repeatStatusListener!);
  }

  @override
  void dispose() {
    _animation!.removeListener(_listener!);
    _animation!.removeStatusListener(_statusListener!);
    controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation!,
      child: widget.child,
      builder: (context, child) {
        if (widget.builder != null) {
          return widget.builder!(_animation, child);
        } else {
          return widget.builderMap!(_animationMap, child);
        }
      },
    );
  }
}
