import 'package:flame/flame.dart';
import 'package:flame/gestures.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:langaw/langaw-game.dart';

import '../view.dart';
import 'callout.dart';

/// create by crius on 2021/4/7
/// email:criusker@163.com
class Fly {
  final LangawGame game;
  Rect flyRect;
  bool isDead = false;
  bool isOffScreen = false;

  double get speed => game.tileSize * 3;
  Offset targetLocation;

  List flyingSprite;
  Sprite deadSprite;
  double flyingSpriteIndex = 0;

  Callout callout;

  Fly(this.game){
    setTargetLocation();
    callout = Callout(this);
  }

  void setTargetLocation() {
    double x = game.rnd.nextDouble() * (game.screenSize.width - (game.tileSize * 1.35));
    double y = (game.rnd.nextDouble() * (game.screenSize.height - (game.tileSize * 2.85))) + (game.tileSize * 1.5);
    targetLocation = Offset(x, y);
  }

  void render(Canvas c){
    if (isDead) {
      deadSprite.renderRect(c, flyRect.inflate(flyRect.width / 2));
    } else {
      flyingSprite[flyingSpriteIndex.toInt()].renderRect(c, flyRect.inflate(flyRect.width / 2));
      if (game.activeView == View.playing) {
        callout.render(c);
      }
    }
  }

  // t -> 时间增量
  void update(double t){
    if(isDead){
      flyRect = flyRect.translate(0, game.tileSize * 12 * t);
    }else{
      // 拍打翅膀
      flyingSpriteIndex += 30 * t;
      while (flyingSpriteIndex >= 2) {
        flyingSpriteIndex -= 2;
      }
      double stepDistance = speed * t;
      Offset toTarget = targetLocation - Offset(flyRect.left, flyRect.top);
      if (stepDistance < toTarget.distance) {
        Offset stepToTarget = Offset.fromDirection(toTarget.direction, stepDistance);
        flyRect = flyRect.shift(stepToTarget);
      } else {
        flyRect = flyRect.shift(toTarget);
        setTargetLocation();
      }
      callout.update(t);
    }

    if(flyRect.top > game.screenSize.height){
      isOffScreen = true;
    }
  }

  void onTapDown(){
    if (!isDead) {
      isDead = true;

      if (game.activeView == View.playing) {
        game.score += 1;
        if (game.score > (game.storage.getInt('highscore') ?? 0)) {
          game.storage.setInt('highscore', game.score);
          game.highscoreDisplay.updateHighscore();
        }
        if (game.soundButton.isEnabled) {
          Flame.audio.play('sfx/ouch' + (game.rnd.nextInt(11) + 1).toString() + '.ogg');
        }
      }
    }
  }
}