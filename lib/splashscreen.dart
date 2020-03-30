import 'dart:async';
import 'package:flame/bgm.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/onboarding.dart';

class SplashScreenPage extends StatefulWidget {
  @override
  _SplashScreenPageState createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  Timer t1, t2;
  bool display = false;
  Bgm bgm;
  @override
  void initState() {
    super.initState();
    bgm = Flame.bgm;
    t1 = new Timer(const Duration(milliseconds: 250), () {
      setState(() {
        display = true;
      });
      bgm.play("ss_audio.opus");
      t2 = new Timer(
        const Duration(milliseconds: 4310),
        () {
          bgm.stop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                return OnBoardingPage();
              },
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedCrossFade(
        firstChild: Container(),
        secondChild: Container(
          height: MediaQuery.of(context).size.height,
          child: Image.asset("assets/ss.gif"),
          color: Color(0xff0D121E),
        ),
        crossFadeState:
            display ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: Duration(
          seconds: 2,
        ),
      ),
    );
  }
}
