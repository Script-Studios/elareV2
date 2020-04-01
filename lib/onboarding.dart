import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/home.dart';
import 'package:flutter_story_app_concept/signInPage.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:intro_slider/slide_object.dart';

class OnBoardingPage extends StatefulWidget {
  @override
  _OnBoardingPageState createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  @override
  Widget build(BuildContext context) {
    List<Slide> pages = new List();
    for (int i = 0; i < 5; i++) {
      pages.add(
        Slide(
          backgroundColor: Colors.transparent,
          title: "page${i + 1}",
          description: "Page ${i + 1} Page ${i + 1}",
          pathImage: "assets/intro_page.jpg",
        ),
      );
    }
    return Container(
      child: IntroSlider(
        slides: pages,
        backgroundColorAllSlides: Colors.transparent,
        onDonePress: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                return SignInPage();
              },
            ),
          );
        },
        colorActiveDot: Colors.white,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1b1e44),
            Color(0xFF2d3447),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          tileMode: TileMode.clamp,
        ),
      ),
    );
  }
}
