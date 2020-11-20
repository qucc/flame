import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../assets/assets_cache.dart';
import '../assets/images.dart';
import '../extensions/vector2.dart';
import '../keyboard.dart';

/// Represents a generic game.
///
/// Subclass this to implement the [update] and [render] methods.
/// Flame will deal with calling these methods properly when the game's widget is rendered.
abstract class Game {
  final images = Images();
  final assets = AssetsCache();
  BuildContext buildContext;

  bool get isAttached => buildContext != null;

  /// Returns the game background color.
  /// By default it will return a black color.
  /// It cannot be changed at runtime, because the game widget does not get rebuild when this value changes.
  Color backgroundColor() => const Color(0xFF000000);

  /// Implement this method to update the game state, given that a time [t] has passed.
  ///
  /// Keep the updates as short as possible. [t] is in seconds, with microseconds precision.
  void update(double t);

  /// Implement this method to render the current game state in the [canvas].
  void render(Canvas canvas);

  /// This is the resize hook; every time the game widget is resized, this hook is called.
  ///
  /// The default implementation does nothing; override to use the hook.
  void onResize(Vector2 size) {}

  /// This is the lifecycle state change hook; every time the game is resumed, paused or suspended, this is called.
  ///
  /// The default implementation does nothing; override to use the hook.
  /// Check [AppLifecycleState] for details about the events received.
  void lifecycleStateChange(AppLifecycleState state) {}

  /// Use for caluclating the FPS.
  void onTimingsCallback(List<FrameTiming> timings) {}

  void _handleKeyEvent(RawKeyEvent e) {
    (this as KeyboardEvents).onKeyEvent(e);
  }

  void attach(PipelineOwner owner, BuildContext context) {
    if(isAttached) {
      throw UnsupportedError("""
      Game attachment error:
      A game instance can only be attached to one widget at a time.
      """);
    }
    buildContext = context;
    onAttach();
  }

  // Called when the Game widget is attached
  @mustCallSuper
  void onAttach() {
    if (this is KeyboardEvents) {
      RawKeyboard.instance.addListener(_handleKeyEvent);
    }
  }

  // Called when the Game widget is detached
  @mustCallSuper
  void onDetach() {
    // Keeping this here, because if we leave this on HasWidgetsOverlay
    // and somebody overrides this and forgets to call the stream close
    // we can face some leaks.

    // Also we only do this in release mode, otherwise when using hot reload
    // the controller would be closed and errors would happen
    if (this is HasWidgetsOverlay && kReleaseMode) {
      (this as HasWidgetsOverlay).widgetOverlayController.close();
    }

    if (this is KeyboardEvents) {
      RawKeyboard.instance.removeListener(_handleKeyEvent);
    }

    images.clearCache();
  }

  /// Flag to tell the game loop if it should start running upon creation
  bool runOnCreation = true;

  /// Pauses the engine game loop execution
  void pauseEngine() => pauseEngineFn?.call();

  /// Resumes the engine game loop execution
  void resumeEngine() => resumeEngineFn?.call();

  VoidCallback pauseEngineFn;
  VoidCallback resumeEngineFn;

  /// Use this method to load the assets need for the game instance to run
  Future<void> onLoad() async {}


}

class ActiveOverlaysNotifier extends ChangeNotifier {
  final Set<String> activeOverlays = {};

  bool add(String overlayName) {
    final setChanged = activeOverlays.add(overlayName);
    if (setChanged) {
      notifyListeners();
    }
    return setChanged;
  }
  bool remove(String overlayName) {
    final hasRemoved = activeOverlays.remove(overlayName);
    if (hasRemoved) {
      notifyListeners();
    }
    return hasRemoved;
  }
}

mixin HasWidgetsOverlay on Game {
  final overlays = ActiveOverlaysNotifier();
}
