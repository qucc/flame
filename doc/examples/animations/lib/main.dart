import 'package:flame/gestures.dart';
import 'package:flutter/gestures.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/extensions/vector2.dart';
import 'package:flame/sprite_animation.dart';
import 'package:flame/components/sprite_animation_component.dart';
import 'package:flutter/material.dart' hide Image;
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final Vector2 size = await Flame.util.initialDimensions();
  final game = MyGame(size);
  runApp(game.widget);
}

class MyGame extends BaseGame with TapDetector {
  Image chopper;
  Image creature;
  SpriteAnimation animation;

  @override
  Future<void> onLoad() async {
    chopper = await images.load('chopper.png');
    creature = await images.load('creature.png');

    animation = SpriteAnimation.sequenced(
      chopper,
      4,
      textureSize: Vector2.all(48),
      stepTime: 0.15,
      loop: true,
    );
  }

  void addAnimation(double x, double y) {
    final size = Vector2(291, 178);

    final animationComponent = SpriteAnimationComponent.sequenced(
      size,
      creature,
      18,
      amountPerRow: 10,
      textureSize: size,
      stepTime: 0.15,
      loop: false,
      removeOnFinish: true,
    );

    animationComponent.position = animationComponent.position - size / 2;
    add(animationComponent);

    final spriteSize = Vector2.all(100.0);
    final animationComponent2 = SpriteAnimationComponent(spriteSize, animation);
    animationComponent2.x = size.x / 2 - spriteSize.x;
    animationComponent2.y = spriteSize.y;

    final reversedAnimationComponent = SpriteAnimationComponent(
      spriteSize,
      animation.reversed(),
    );
    reversedAnimationComponent.x = size.x / 2;
    reversedAnimationComponent.y = spriteSize.y;

    add(animationComponent2);
    add(reversedAnimationComponent);
  }

  @override
  void onTapDown(TapDownDetails evt) {
    addAnimation(evt.globalPosition.dx, evt.globalPosition.dy);
  }

  MyGame(Vector2 screenSize) {
    size = screenSize;
  }
}
