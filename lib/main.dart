import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/dummy.dart';
import 'package:flutter_story_app_concept/home.dart';
import 'package:flutter_story_app_concept/onboarding.dart';
import 'package:flutter_story_app_concept/signInPage.dart';
import 'package:flutter_story_app_concept/splashscreen.dart';

void main() => runApp(
      MaterialApp(
        routes: {
          'home': (context) => Home(),
          'dummy': (context) => Dummy(),
          'splash': (context) => SplashScreenPage(),
          'onboarding': (context) => OnBoardingPage(),
          'signin': (context) => SignInPage(),
        },
        initialRoute: 'splash',
        debugShowCheckedModeBanner: false,
      ),
    );
