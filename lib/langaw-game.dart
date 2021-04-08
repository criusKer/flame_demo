import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:langaw/components/backyard.dart';
import 'package:langaw/components/fly.dart';
import 'package:flame/gestures.dart';
import 'package:langaw/components/house-fly.dart';
import 'package:langaw/view.dart';
import 'package:langaw/views/credits-view.dart';
import 'package:langaw/views/help-view.dart';
import 'package:langaw/views/lost-view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/agile-fly.dart';
import 'components/credits-button.dart';
import 'components/drooler-fly.dart';
import 'components/help-button.dart';
import 'components/highscore-display.dart';
import 'components/hungry-fly.dart';
import 'components/macho-fly.dart';
import 'components/music-button.dart';
import 'components/score-display.dart';
import 'components/sound-button.dart';
import 'components/start-button.dart';
import 'controllers/spawner.dart';
import 'views/home-view.dart';
import 'package:audioplayers/audioplayers.dart';

/// create by crius on 2021/4/7
/// email:criusker@163.com
class LangawGame extends Game with TapDetector {
  Size screenSize;
  double tileSize;
  List<Fly> flies;
  Random rnd;

  Backyard backyard;
  HomeView homeView;
  StartButton startButton;
  LostView lostView;
  FlySpawner spawner;
  HelpButton helpButton;
  CreditsButton creditsButton;
  HelpView helpView;
  CreditsView creditsView;
  ScoreDisplay scoreDisplay;
  HighscoreDisplay highscoreDisplay;
  MusicButton musicButton;
  SoundButton soundButton;

  View activeView = View.home;
  // 记录分数
  int score;

  final SharedPreferences storage;
  AudioPlayer homeBGM;
  AudioPlayer playingBGM;

  LangawGame(this.storage){
    initialize();
  }

  void initialize() async {
    flies = List<Fly>();
    resize(await Flame.util.initialDimensions());

    rnd = Random();
    score = 0;

    backyard = Backyard(this);
    homeView = HomeView(this);
    startButton = StartButton(this);
    lostView = LostView(this);
    spawner = FlySpawner(this);
    helpButton = HelpButton(this);
    creditsButton = CreditsButton(this);
    helpView = HelpView(this);
    creditsView = CreditsView(this);
    scoreDisplay = ScoreDisplay(this);
    highscoreDisplay = HighscoreDisplay(this);
    musicButton = MusicButton(this);
    soundButton = SoundButton(this);

    homeBGM = await Flame.audio.loop('bgm/home.mp3', volume: .25);
    homeBGM.pause();
    playingBGM = await Flame.audio.loop('bgm/playing.mp3', volume: .25);
    playingBGM.pause();

    playHomeBGM();
  }

  void playHomeBGM() {
    playingBGM.pause();
    // playingBGM.seek(Duration.zero);
    homeBGM.resume();
  }

  void playPlayingBGM() {
    homeBGM.pause();
    // homeBGM.seek(Duration.zero);
    playingBGM.resume();
  }

  // 召唤小飞蝇
  void spawnFly(){
    double x = rnd.nextDouble() * (screenSize.width - (tileSize * 1.35));
    double y = (rnd.nextDouble() * (screenSize.height - (tileSize * 2.85))) + (tileSize * 1.5);

    switch (rnd.nextInt(5)) {
      case 0:
        flies.add(HouseFly(this, x, y));
        break;
      case 1:
        flies.add(DroolerFly(this, x, y));
        break;
      case 2:
        flies.add(AgileFly(this, x, y));
        break;
      case 3:
        flies.add(MachoFly(this, x, y));
        break;
      case 4:
        flies.add(HungryFly(this, x, y));
        break;
    }
  }

  void render(Canvas canvas) {
    // 绘制背景
    // Rect bgRect = Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
    // Paint bgPaint = Paint();
    // bgPaint.color = Color(0xff576574);
    // canvas.drawRect(bgRect, bgPaint);
    backyard.render(canvas);
    // 最高分
    highscoreDisplay.render(canvas);
    musicButton.render(canvas);
    soundButton.render(canvas);
    // 游戏时分数
    if (activeView == View.playing) scoreDisplay.render(canvas);
    // 绘制每一只小飞蝇
    flies.forEach((Fly fly) => fly.render(canvas));
    if (activeView == View.home) homeView.render(canvas);
    if (activeView == View.home || activeView == View.lost) {
      startButton.render(canvas);
      helpButton.render(canvas);
      creditsButton.render(canvas);
    }
    if (activeView == View.lost) lostView.render(canvas);
    if (activeView == View.help) helpView.render(canvas);
    if (activeView == View.credits) creditsView.render(canvas);
  }

  void update(double t) {
    // 调用每一个小飞蝇的update方法
    flies.forEach((Fly fly) => fly.update(t));
    flies.removeWhere((Fly fly) => fly.isOffScreen);
    spawner.update(t);
    if (activeView == View.playing) scoreDisplay.update(t);
  }

  void resize(Size size) {
    screenSize = size;
    tileSize = screenSize.width / 9;
  }

  void onTapDown(TapDownDetails details) {

    bool isHandled = false;

    // 音乐按钮
    if (!isHandled && musicButton.rect.contains(details.globalPosition)) {
      musicButton.onTapDown();
      isHandled = true;
    }

// 音效按钮
    if (!isHandled && soundButton.rect.contains(details.globalPosition)) {
      soundButton.onTapDown();
      isHandled = true;
    }

    // 弹窗
    if (!isHandled) {
      if (activeView == View.help || activeView == View.credits) {
        activeView = View.home;
        isHandled = true;
      }
    }

    if(!isHandled && startButton.rect.contains(details.globalPosition)){
      if(activeView == View.home || activeView == View.lost){
        startButton.onTapDown();
        isHandled = true;
      }
    }
    if(!isHandled){
      bool didHitAFly = false;
      flies.forEach((Fly fly) {
        if(fly.flyRect.contains(details.globalPosition)){
          fly.onTapDown();
          isHandled = true;
          didHitAFly = true;
        }
      });
      if (activeView == View.playing && !didHitAFly) {
        if (soundButton.isEnabled) {
          Flame.audio.play('sfx/haha' + (rnd.nextInt(5) + 1).toString() + '.ogg');
        }
        playHomeBGM();
        activeView = View.lost;
      }
    }

    // 教程按钮
    if (!isHandled && helpButton.rect.contains(details.globalPosition)) {
      if (activeView == View.home || activeView == View.lost) {
        helpButton.onTapDown();
        isHandled = true;
      }
    }

// 感谢按钮
    if (!isHandled && creditsButton.rect.contains(details.globalPosition)) {
      if (activeView == View.home || activeView == View.lost) {
        creditsButton.onTapDown();
        isHandled = true;
      }
    }
  }
}