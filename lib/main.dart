import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/aboutUs.dart';
import 'package:flutter_story_app_concept/dummy.dart';
import 'package:flutter_story_app_concept/home.dart';
import 'package:flutter_story_app_concept/interests.dart';
import 'package:flutter_story_app_concept/onboarding.dart';
import 'package:flutter_story_app_concept/signInPage.dart';
import 'package:flutter_story_app_concept/splashscreen.dart';
import 'package:flutter_story_app_concept/tutorial.dart';

void main() => runApp(
      MaterialApp(
        theme: ThemeData(
          fontFamily: "AmaticSCBold",
        ),
        routes: {
          'home': (context) => Home(),
          'dummy': (context) => Dummy(),
          'splash': (context) => SplashScreenPage(),
          'onboarding': (context) => OnBoardingPage(),
          'signin': (context) => SignInPage(),
          'interests': (context) => SelectInterests(),
          'tutorial': (context) => TutorialPage(),
          'about': (context) => AboutUsPage(),
        },
        initialRoute: 'splash',
        debugShowCheckedModeBanner: false,
      ),
    );
