import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flame/bgm.dart';
import 'package:flame/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/cards.dart';
import 'package:flutter_story_app_concept/dataClasses.dart';
import 'package:flutter_story_app_concept/gameTimer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter_animation_set/widget/transition_animations.dart';
import 'package:flutter_animation_set/widget/behavior_animations.dart';

class TutorialPage extends StatefulWidget {
  @override
  _TutorialPageState createState() => new _TutorialPageState();
}

var cardAspectRatio = 12.0 / 16.0;
var widgetAspectRatio = cardAspectRatio * 1.2;
//var images = dataimages;

class _TutorialPageState extends State<TutorialPage> {
  GameTimer t;
  Connectivity connect;
  List<CardScrollWidget> themes;
  CardScrollWidget cards;
  List<ImageShow> images, shownImages;
  List<Swipe> swipes;
  int score;
  int life = 3;
  bool gameTutorialFinished;
  bool loading = true;
  List<Widget> lives, lifeGone;
  GlobalKey _left = new GlobalKey(),
      _right = new GlobalKey(),
      _score = new GlobalKey(),
      _time = new GlobalKey(),
      _life = new GlobalKey();
  Bgm bgm;
  int imagesLoaded = 0;
  FlameAudio flameAudio;
  List<GameTheme> gameThemes;
  bool themeLoading = false;
  int tuts = 3, mist = 0;

  void swipeAudio() {
    flameAudio.play("swipe.mp3");
  }

  void wrongSwipeAudio() {
    flameAudio.play("wrongSwipe.mp3");
  }

  void gameOverAudio() async {
    bgm.play("gameOver.mp3");
  }

  void loadingDialog() async {
    await Future.delayed(const Duration(seconds: 5));
    setState(() {
      loading = false;
      loadAudio();
    });
  }

  void removeImage(int swipe) {
    if (swipes.length == 0) t.startTimer();
    var current = shownImages.removeLast();
    int correctSwipe = current.image.type;
    if (swipe == correctSwipe) {
      score += 10;
      swipeAudio();
    } else {
      life -= 1;
      if (life == 2) mist = 1;
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
    swipes.add(
      new Swipe(image: current, swipe: swipe),
    );
    if (images.length > 0) shownImages.insert(0, images.removeAt(0));

    if (life == 0) {
      bgm.stop();
      gameOverAudio();
      gameOver();
    }
    setState(() {});
  }

  void lifeRemoved() async {
    await Future.delayed(Duration(milliseconds: 1500));
    setState(() {
      lifeGone[0] = Spacer();
    });
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
    images.shuffle();
    for (int i = 0; i < 6; i++) {
      shownImages.add(images.removeAt(i));
    }
    cards = new CardScrollWidget(removeImage, shownImages);
    setState(() {
      themeLoading = false;
    });
    loadingDialog();
  }

  void gameOver() {
    t.endTimer();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1b1e44 + 0xFF2d3447),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        title: Text(
          "Game Over",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        content: Text(
          "Your Score: $score",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text(
              "Ok",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
              ),
            ),
            onPressed: () {
              bgm.stop();
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('home');
            },
          ),
        ],
      ),
    );
  }

  void loadAudio() async {
    //bgm.play("gameAudio.mp3");
  }

  void startTutorial(BuildContext context) async {
    var current = shownImages.last;
    tuts -= 1;
    await Future.delayed(Duration(milliseconds: 500));
    if (current.image.type == 0) {
      ShowCaseWidget.of(context).startShowCase([_left]);
    } else {
      ShowCaseWidget.of(context).startShowCase([_right]);
    }
  }

  void mistakeTutorial(BuildContext context) async {
    mist -= 1;
    await Future.delayed(Duration(milliseconds: 500));
    ShowCaseWidget.of(context).startShowCase([_life]);
  }

  @override
  void initState() {
    super.initState();
    gameThemes = new List();
    images = new List();
    shownImages = new List();
    swipes = new List();
    score = 0;
    bgm = new Bgm();
    bgm.loadAll(["gameAudio.mp3", "gameOver.mp3"]);
    flameAudio = new FlameAudio();
    flameAudio.loadAll(["wrongSwipe.mp3", "swipe.mp3"]);
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
    t = new GameTimer(
      reverse: false,
      initDuration: null,
      style: TextStyle(
        color: Colors.white,
        fontSize: 25,
      ),
      timerEnd: gameOver,
    );
  }

  @override
  void dispose() {
    bgm.clearAll();
    flameAudio.clearAll();
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
        ShowCaseWidget(
          onFinish: () async {},
          builder: Builder(
            builder: (context) {
              if (current != null && !loading && tuts > 0)
                startTutorial(context);
              else if (tuts == 0 && mist == 1) {
                mistakeTutorial(context);
              }
              return Container(
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
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pushNamed('home');
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(4),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                        Expanded(
                                          child: Showcase(
                                              key: _life,
                                              child: AutoSizeText(
                                                "Lives:",
                                                minFontSize: 20,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              description:
                                                  "Beware, a wrong swipe could cost you a life\nYou only got 3"),
                                        ),
                                      ] +
                                      lives +
                                      lifeGone +
                                      [
                                        Spacer(),
                                        Showcase(
                                          key: _score,
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
                                                    vertical: 6.0),
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
                                          description:
                                              "Current Score. If score goes less than 0,\nthen game over!!",
                                        ),
                                      ],
                                ),
                              ),
                            )
                          : SizedBox(),
                      current != null
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
                          : SizedBox(),
                      current != null
                          ? Expanded(
                              flex: 13,
                              child: LayoutBuilder(
                                builder: (context, cons) {
                                  return SizedBox(
                                    child: cards,
                                    height: cons.biggest.height,
                                    width:
                                        cons.biggest.height * widgetAspectRatio,
                                  );
                                },
                              ),
                            )
                          : SizedBox(),
                      current != null
                          ? Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 20.0),
                                child: Row(
                                  children: <Widget>[
                                    Spacer(
                                      flex: 1,
                                    ),
                                    Expanded(
                                      flex: 6,
                                      child: Showcase(
                                        key: _left,
                                        child: FlatButton(
                                          onPressed: () {
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
                                        description:
                                            "Current Image seems to be a ${current.type0},\nswipe left the image\nor Press this button",
                                      ),
                                    ),
                                    Spacer(
                                      flex: 1,
                                    ),
                                    Expanded(
                                      flex: 6,
                                      child: Showcase(
                                          key: _right,
                                          child: FlatButton(
                                            onPressed: () {
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                          description:
                                              "Current Image seems to be a ${current.type1},\nswipe right the image\nor Press this button"),
                                    ),
                                    Spacer(
                                      flex: 1,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SizedBox(),
                      Spacer(
                        flex: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
    return stack;
  }
}
