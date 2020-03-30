import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/home.dart';
import 'package:intro_views_flutter/Models/page_view_model.dart';
import 'package:intro_views_flutter/intro_views_flutter.dart';

class OnBoardingPage extends StatefulWidget {
  @override
  _OnBoardingPageState createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  @override
  Widget build(BuildContext context) {
    List<PageViewModel> pages = new List();
    for (int i = 0; i < 5; i++) {
      pages.add(
        PageViewModel(
          pageColor: Colors.transparent,
          title: Text("page${i + 1}"),
          body: Text("Page ${i + 1} Page ${i + 1}"),
          mainImage: Image.asset(
            "assets/intro_page.jpg",
          ),
        ),
      );
    }
    return Container(
      child: IntroViewsFlutter(
        pages,
        background: Colors.transparent,
        onTapDoneButton: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                return Home();
              },
            ),
          );
        },
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
