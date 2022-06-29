import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/cards.dart';
import 'package:flutter_story_app_concept/dataClasses.dart';
import 'package:flutter_story_app_concept/gameTimer.dart';
import 'package:flutter_story_app_concept/main.dart';
import 'package:flutter_animation_set/widget/transition_animations.dart';
import 'package:flutter_animation_set/widget/behavior_animations.dart';

class TutorialPage extends StatefulWidget {
  final bool firstInstall;
  TutorialPage({@required this.firstInstall});
  @override
  _TutorialPageState createState() => new _TutorialPageState();
}

var cardAspectRatio = 12.0 / 16.0;
var widgetAspectRatio = cardAspectRatio * 1.2;
//var images = dataimages;

class _TutorialPageState extends State<TutorialPage>
    with WidgetsBindingObserver {
  GameTimer t;
  Connectivity connect;
  List<CardScrollWidget> themes;
  CardScrollWidget cards;
  List<ImageShow> images, shownImages;
  //List<Swipe> swipes;
  int score;
  int life = 3;
  bool gameTutorialFinished;
  bool loading = true;
  List<Widget> lives, lifeGone;
  int imagesLoaded = 0;
  List<GameTheme> gameThemes;
  bool themeLoading = false;
  int tuts = 3, mist = 0, step = 0;
  List<String> tutText;
  bool nextEnable = false;
  int tutSwiped = 0;

  void swipeAudio() {
    playAudio("swipe.mp3");
  }

  void wrongSwipeAudio() {
    playAudio("wrongSwipe.mp3");
  }

  void gameOverAudio() async {
    playBgm("gameOver.mp3");
  }

  void loadingDialog() async {
    await Future.delayed(const Duration(seconds: 5));
    setState(() {
      loading = false;
      loadAudio();
    });
  }

  void removeImage(int swipe) {
    //if (swipes.length == 0) t.startTimer();
    var current = shownImages.removeLast();
    int correctSwipe = current.image.type;
    print(current.image.type == correctSwipe);
    if (images.length > 0) shownImages.insert(0, images.removeAt(0));
    if (step <= 3) {
      //nextEnable = true;
      step += 1;
    } else if (step == 4) {
      tutSwiped += 1;
      if (tutSwiped == 3) nextEnable = true;
    }
    if (step >= 6) {
      if (swipe == correctSwipe) {
        score += 10;
      } else {
        life -= 1;
        wrongSwipeAudio();
        setState(() {
          lives.removeLast();
          lifeGone.insert(
            0,
            Expanded(
              child: YYSingleLike(),
            ),
          );
          lifeRemoved();
        });
      }
      if (life == 0) {
        life = 3;
        lives = [
          Expanded(
            child: YYPumpingHeart(),
          ),
          Expanded(
            child: YYPumpingHeart(),
          ),
          Expanded(
            child: YYPumpingHeart(),
          ),
        ];
      }
    }
    setState(() {});
  }

  void lifeRemoved() async {
    await Future.delayed(Duration(milliseconds: 1500));
    if (life == 3)
      lifeGone = [];
    else
      lifeGone[0] = Spacer();
    setState(() {});
  }

  void shuffleImages() async {
    setState(() {
      themeLoading = true;
    });
    Firestore firestore = Firestore.instance;
    var sp = await firestore
        .collection('themes')
        .where('id', isEqualTo: 'BYGL')
        .getDocuments();
    if (sp.documents.length == 1) {
      var doc = sp.documents.first;
      gameThemes.add(new GameTheme.fromMap(doc.data));
    }
    gameThemes.forEach((theme) {
      theme.images.forEach((image) {
        images.add(
          new ImageShow(
            image: image,
            imgIndex: theme.images.indexOf(image),
            themeId: theme.id,
            type0: theme.type0,
            type1: theme.type1,
          ),
        );
      });
    });
    for (int i = 0; i < 2; i++) {
      shownImages.add(images.removeAt(i));
    }
    images.shuffle();
    for (int i = 0; i < 4; i++) {
      int j;
      if (i % 2 == 1) {
        j = images.indexWhere((im) {
          return im.image.type == 1;
        });
      } else {
        j = images.indexWhere((im) {
          return im.image.type == 0;
        });
      }
      shownImages.add(images.removeAt(j));
    }
    cards = new CardScrollWidget(removeImage, shownImages);
    setState(() {
      themeLoading = false;
    });
    loadingDialog();
  }

  void loadAudio() async {
    try {
      playBgm(gameAudio);
    } catch (e) {
      print(e);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive) {
      if (this.mounted) {
        ap.setVolume(0);
        bgm.pause();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (this.mounted) {
        ap.setVolume(1);
        bgm.resume();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    gameThemes = new List();
    images = new List();
    shownImages = new List();
    score = 0;
    lives = [
      Expanded(
        child: YYPumpingHeart(),
      ),
      Expanded(
        child: YYPumpingHeart(),
      ),
      Expanded(
        child: YYPumpingHeart(),
      ),
    ];
    lifeGone = [];
    shuffleImages();
    tutText = [
      "Right Swipe this Image !",
      "Now, Left Swipe this Image !",
      "These buttons denote the possible categories of the image. Instead of swiping, you may use these buttons too ! For Example, this is a girl. Press the right button !",
      "This is a Boy. Press the left button !",
      "Swipe at least three images as per your intuition !",
      "You get three lives ! An incorrect swipe will cost you a life !",
      "Keep checking the Scorecard !",
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageShow current;
    if (shownImages.length > 0) {
      current = shownImages.last;
    }
    var stack = new IndexedStack(
      index: loading ? 0 : 1,
      children: <Widget>[
        Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                "LOADING YOUR Tutorial\n......",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.pink,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 5,
                ),
              ),
              Image.asset("assets/loading.gif"),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [
                  Color(0xFF1b1e44),
                  Color(0xFF2d3447),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                tileMode: TileMode.clamp),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 12.0, right: 12.0, top: 40.0, bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Spacer(),
                        Expanded(
                          flex: 2,
                          child: AutoSizeText(
                            "Tutorial",
                            minFontSize: 50,
                            maxLines: 1,
                            maxFontSize: 60,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: FlatButton(
                            onPressed: () {
                              if (widget.firstInstall) {
                                Navigator.of(context).pop();
                                Navigator.of(context).pushNamed('signin');
                              } else {
                                Navigator.of(context).pop();
                                Navigator.of(context).pushNamed('home');
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.blueAccent,
                              ),
                              child: AutoSizeText(
                                "End Tutorial",
                                minFontSize: 20,
                                maxFontSize: 60,
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                current != null
                    ? Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                                  Expanded(
                                    child: AnimatedCrossFade(
                                      firstChild: AutoSizeText(
                                        "Lives:",
                                        minFontSize: 20,
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      secondChild: Container(),
                                      crossFadeState: step >= 5
                                          ? CrossFadeState.showFirst
                                          : CrossFadeState.showSecond,
                                      duration: Duration(milliseconds: 500),
                                    ),
                                  ),
                                ] +
                                (step >= 5 ? lives : []) +
                                (step >= 5 ? lifeGone : []) +
                                [
                                  Spacer(),
                                  AnimatedCrossFade(
                                    firstChild: Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xFFff6e6e),
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                      child: Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 22.0, vertical: 6.0),
                                          child: AutoSizeText(
                                            "Score: $score",
                                            minFontSize: 25,
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    secondChild: Container(),
                                    crossFadeState: step >= 6
                                        ? CrossFadeState.showFirst
                                        : CrossFadeState.showSecond,
                                    duration: Duration(milliseconds: 500),
                                  ),
                                ],
                          ),
                        ),
                      )
                    : SizedBox(),
                /* current != null
                          ? Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 12.0,
                                    right: 12.0,
                                    top: 8.0,
                                    bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    Showcase(
                                      key: _time,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Color(0xFFff6e6e),
                                          borderRadius:
                                              BorderRadius.circular(20.0),
                                        ),
                                        child: Center(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 22.0,
                                              vertical: 6.0,
                                            ),
                                            child: t,
                                          ),
                                        ),
                                      ),
                                      description: "Elapsed Time." +
                                          "\nTry to swipe as many\n images as possible\nwithin this time.",
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SizedBox(), */
                current != null
                    ? Expanded(
                        flex: 13,
                        child: LayoutBuilder(
                          builder: (context, cons) {
                            return SizedBox(
                              child: cards,
                              height: cons.biggest.height,
                              width: cons.biggest.height * widgetAspectRatio,
                            );
                          },
                        ),
                      )
                    : SizedBox(),
                current != null
                    ? Expanded(
                        flex: 3,
                        child: AnimatedCrossFade(
                          firstChild: Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: Row(
                              children: <Widget>[
                                Spacer(
                                  flex: 1,
                                ),
                                Expanded(
                                  flex: 6,
                                  child: FlatButton(
                                    onPressed: step == 2
                                        ? null
                                        : () {
                                            swipeAudio();
                                            cards.card.swipeLeft();
                                          },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent,
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 22.0),
                                        child: AutoSizeText(
                                          current.type0,
                                          textAlign: TextAlign.center,
                                          minFontSize: 22,
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Spacer(
                                  flex: 1,
                                ),
                                Expanded(
                                  flex: 6,
                                  child: FlatButton(
                                    onPressed: step == 3
                                        ? null
                                        : () {
                                            swipeAudio();
                                            cards.card.swipeRight();
                                          },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent,
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 22.0),
                                        child: AutoSizeText(
                                          current.type1,
                                          textAlign: TextAlign.center,
                                          minFontSize: 22,
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                          maxLines: 5,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Spacer(
                                  flex: 1,
                                ),
                              ],
                            ),
                          ),
                          secondChild: Container(),
                          crossFadeState: step >= 2
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          duration: Duration(milliseconds: 500),
                        ),
                      )
                    : Spacer(
                        flex: 3,
                      ),
                Expanded(
                  flex: step == 7 ? 1 : 5,
                  child: AnimatedCrossFade(
                    firstChild: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: step == 7
                          ? Container()
                          : Column(
                              children: <Widget>[
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    alignment: Alignment.topLeft,
                                    child: AnimatedCrossFade(
                                      firstChild: step < 7
                                          ? AutoSizeText(
                                              tutText[step],
                                              textAlign: TextAlign.start,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'MeriendaBold',
                                              ),
                                              //minFontSize: 20,
                                              maxLines: 3,
                                            )
                                          : Container(),
                                      secondChild: step < 6
                                          ? AutoSizeText(
                                              tutText[step + 1],
                                              textAlign: TextAlign.start,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'MeriendaBold',
                                              ),
                                              //minFontSize: 20,
                                              maxLines: 3,
                                            )
                                          : Container(),
                                      crossFadeState: CrossFadeState.showFirst,
                                      duration: Duration(milliseconds: 500),
                                    ),
                                    padding:
                                        EdgeInsets.only(left: 15, right: 5),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: FlatButton(
                                      padding: EdgeInsets.only(bottom: 5.0),
                                      onPressed: nextEnable
                                          ? () {
                                              setState(() {
                                                if (step < 4)
                                                  nextEnable = false;
                                                step += 1;
                                              });
                                            }
                                          : null,
                                      child: AutoSizeText(
                                        step == 6 ? "Finish" : "Next",
                                        style: TextStyle(
                                          color: nextEnable
                                              ? Colors.white
                                              : Colors.grey[850],
                                        ),
                                        minFontSize: 25,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    secondChild: Container(),
                    crossFadeState: step == 7
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: Duration(milliseconds: 750),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    return WillPopScope(
        child: stack,
        onWillPop: () async {
          return false;
        });
  }
}
