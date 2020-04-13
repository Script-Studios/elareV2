import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flame/bgm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/signInPage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnBoardingPage extends StatefulWidget {
  @override
  _OnBoardingPageState createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  PageController cont;
  int pos = 0;
  List<Color> colors = [
    Color(0xFF1b1e44),
    Color(0xFF8ED547),
    Color(0xFF1b1e44),
    Color(0xFFF2BB25),
    Color(0xFF126C20),
  ];
  List<String> titles = [
    "Swipe Left Right",
    "Breaking the Ice ",
    "Play as per your interests",
    "Latest Categories ",
  ],
      desc = [
    "Can you match the image with the text mentioned below ?",
    "We would like to know about Who you are !",
    "Select all that you like from the platter of themes !",
    "Play ! Score More ! Unlock levels and themes !",
  ],
      images = [
    "https://firebasestorage.googleapis.com/v0/b/elare-bd2f2.appspot.com/o/assets%2Fintro1.png?alt=media&token=d2490fb3-5877-4902-9385-4bf7717bc21b",
    "https://firebasestorage.googleapis.com/v0/b/elare-bd2f2.appspot.com/o/assets%2Fintro2.png?alt=media&token=3378e8a7-a4f8-4143-9e27-948d7ed40d9f",
    "https://firebasestorage.googleapis.com/v0/b/elare-bd2f2.appspot.com/o/assets%2Fintro3.png?alt=media&token=034233e8-ed68-43a1-927b-d885efe4d44f",
    "https://firebasestorage.googleapis.com/v0/b/elare-bd2f2.appspot.com/o/assets%2Fintro4.png?alt=media&token=bb684d64-9946-4504-abb8-481296834c27",
  ];
  Bgm bgm;

  Widget nextButton(int i) {
    if (i == titles.length - 1) {
      return SizedBox();
    } else {
      return FlatButton(
        onPressed: () {
          cont.nextPage(
            duration: const Duration(milliseconds: 750),
            curve: Curves.ease,
          );
          pos += 1;
          setState(() {});
        },
        child: Icon(
          Icons.arrow_forward,
          size: 35,
          color: Colors.white,
        ),
        /* child: AutoSizeText(
          "Next",
          minFontSize: 20,
          maxLines: 1,
          style: TextStyle(
            color: Colors.white,
          ),
        ), */
      );
    }
  }

  Widget backButton(int i) {
    if (i == 0) {
      return SizedBox();
    } else {
      return FlatButton(
        onPressed: () async {
          await cont.previousPage(
            duration: const Duration(milliseconds: 750),
            curve: Curves.ease,
          );
          setState(() {});
        },
        child: Icon(
          Icons.arrow_back,
          size: 35,
          color: Colors.white,
        ),
        /* child: AutoSizeText(
          "Back",
          minFontSize: 20,
          maxLines: 1,
          style: TextStyle(
            color: Colors.white,
          ),
        ), */
      );
    }
  }

  Widget skipButton(int i) {
    return FlatButton(
      onPressed: () async {
        cont.animateToPage(
          titles.length - 1,
          duration: Duration(milliseconds: 1000),
          curve: Curves.ease,
        );
        setState(() {});
      },
      child: AutoSizeText(
        "Skip",
        minFontSize: 20,
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }

  Widget doneButton(int i) {
    return FlatButton(
      onPressed: onBoardingFinished,
      child: AutoSizeText(
        "Done",
        minFontSize: 20,
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }

  void onBoardingFinished() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool("onBoardingDone", true);
    bgm.stop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return SignInPage();
        },
      ),
    );
  }

  void startMusic() async {
    bgm = new Bgm();
    await bgm.load("onboard.mp3");
    bgm.play("onboard.mp3");
  }

  @override
  void initState() {
    super.initState();
    startMusic();
    cont = new PageController();
  }

  @override
  void dispose() {
    bgm.stop();
    bgm.clearAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: PageView.builder(
          controller: cont,
          itemCount: titles.length,
          itemBuilder: (context, i) {
            return Scaffold(
              backgroundColor: colors[i],
              body: Column(
                children: <Widget>[
                  Spacer(
                    flex: 1,
                  ),
                  i < titles.length - 1
                      ? Expanded(
                          flex: 1,
                          child: Align(
                            child: skipButton(i),
                            alignment: Alignment.centerRight,
                          ),
                        )
                      : Spacer(
                          flex: 1,
                        ),
                  Spacer(
                    flex: 1,
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      titles[i],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: CachedNetworkImage(
                      imageUrl: images[i],
                      placeholder: (context, s) {
                        return Container(
                          child: Center(
                            child: CircularProgressIndicator(
                              backgroundColor: Colors.white,
                            ),
                          ),
                          color: colors[i],
                        );
                      },
                      errorWidget: (context, s, o) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.error_outline,
                                color: Colors.white,
                              ),
                              Text(
                                "Error loading",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Spacer(
                    flex: 1,
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      desc[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        i > 0
                            ? Expanded(
                                child: backButton(i),
                              )
                            : Spacer(),
                        i < titles.length - 1
                            ? Expanded(
                                child: nextButton(i),
                              )
                            : Expanded(
                                child: doneButton(i),
                              ),
                      ],
                    ),
                  ),
                  Spacer(
                    flex: 1,
                  ),
                ],
              ),
            );
          }),
    );
  }
}
