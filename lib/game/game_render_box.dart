import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart' hide WidgetBuilder;

import '../extensions/size.dart';
import 'game.dart';
import 'game_loop.dart';

class GameRenderBox extends RenderBox with WidgetsBindingObserver {
  BuildContext context;
  Game game;
  GameLoop gameLoop;

  GameRenderBox(this.context, this.game) {
    gameLoop = GameLoop(gameLoopCallback);
    WidgetsBinding.instance.addTimingsCallback(game.onTimingsCallback);
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    super.performResize();
    game.onResize(constraints.biggest.toVector2());
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    game.onAttach();

    game.pauseEngineFn = gameLoop.pause;
    game.resumeEngineFn = gameLoop.resume;

    if (game.runOnCreation) {
      gameLoop.start();
    }

    _bindLifecycleListener();
  }

  @override
  void detach() {
    super.detach();
    game.onDetach();
    gameLoop.stop();
    _unbindLifecycleListener();
  }

  void gameLoopCallback(double dt) {
    if (!attached) {
      return;
    }
    game.update(dt);
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.save();
    final delta = game.builder.offset + offset;
    context.canvas.translate(delta.dx, delta.dy);
    game.render(context.canvas);
    context.canvas.restore();
  }

  void _bindLifecycleListener() {
    WidgetsBinding.instance.addObserver(this);
  }

  void _unbindLifecycleListener() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    game.lifecycleStateChange(state);
  }
}
