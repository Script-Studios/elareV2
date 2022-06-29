import 'package:audioplayers/audioplayers.dart';
import 'package:flame/bgm.dart';
import 'package:flame/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/home.dart';
import 'package:flutter_story_app_concept/aboutUs.dart';
import 'package:flutter_story_app_concept/dummy.dart';
import 'package:flutter_story_app_concept/leaderBoard.dart';
import 'package:flutter_story_app_concept/settingsPage.dart';
import 'package:flutter_story_app_concept/themes.dart';
import 'package:flutter_story_app_concept/interests.dart';
import 'package:flutter_story_app_concept/onboarding.dart';
import 'package:flutter_story_app_concept/signInPage.dart';
import 'package:flutter_story_app_concept/splashscreen.dart';
import 'package:flutter_story_app_concept/tutorial.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(
      MaterialApp(
        theme: ThemeData(
          fontFamily: "AmaticSCBold",
        ),
        routes: {
          'home': (context) => HomePage(),
          'themes': (context) => ThemeSelection(),
          'dummy': (context) => Dummy(),
          'splash': (context) => SplashScreenPage(),
          'onboarding': (context) => OnBoardingPage(),
          'signin': (context) => SignInPage(),
          'interests': (context) => SelectInterests(),
          'tutorial': (context) => TutorialPage(firstInstall: false),
          'about': (context) => AboutUsPage(),
          'leaderboard': (context) => LeaderBoardDialog(),
        },
        initialRoute: 'splash',
        debugShowCheckedModeBanner: false,
      ),
    );

Bgm bgm;
FlameAudio flameAudio;
AudioPlayer ap;
bool music = true;
String gameAudio;
User me;

void loadAudioPlayers() async {
  bgm = Bgm();
  flameAudio = new FlameAudio();
  SharedPreferences preferences = await SharedPreferences.getInstance();
  music = preferences.getBool("music");
  if (music == null) music = true;
  await flameAudio.load("ss_audio.mp3");
  playAudio("ss_audio.mp3");
  flameAudio.loadAll(["wrongSwipe.mp3", "swipe.mp3"]);
  bgm.loadAll([
    "onboard.mp3",
    "gameAudio1.mp3",
    "gameAudio2.mp3",
    "gameAudio3.mp3",
    "gameOver.mp3",
  ]);

  gameAudio = preferences.getString("gameAudio");
  if (gameAudio == null) gameAudio = "gameAudio1.mp3";
}

void playBgm(String loc) {
  if (music) {
    if (bgm.isPlaying) bgm.stop();
    bgm.play(loc);
  }
}

void stopBgm() {
  if (music && bgm.isPlaying) bgm.stop();
}

void playAudio(String loc) async {
  if (music) {
    if (ap != null) {
      await ap.stop();
    }
    ap = await flameAudio.play(loc);
  }
}

void stopAudio() async {
  if (music) {
    if (ap != null) {
      await ap.stop();
    }
  }
}
