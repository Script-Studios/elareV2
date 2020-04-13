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

class NewGame extends StatefulWidget {
  final List<GameTheme> themes;
  final int mode; //0 for timed, 1 for endless
  NewGame({@required this.themes, @required this.mode});
  @override
  _NewGameState createState() => new _NewGameState();
}

var cardAspectRatio = 12.0 / 16.0;
var widgetAspectRatio = cardAspectRatio * 1.2;
//var images = dataimages;

class _NewGameState extends State<NewGame> {
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
      _time = new GlobalKey();
  Bgm bgm;
  int imagesLoaded = 0;
  FlameAudio flameAudio;

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
    await Future.delayed(const Duration(seconds: 10));
    setState(() {
      loading = false;
      loadAudio();
      startTutorial(context);
    });
  }

  void removeImage(int swipe) {
    if (swipes.length == 0) t.startTimer();
    var current = shownImages.removeLast();
    int correctSwipe = current.image.type;
    if (swipe == correctSwipe) {
      score += 10;
      swipeAudio();
      //(counterKey.currentState as MultipleDigitCounterState).value = score;
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

  Future<void> shuffleImages() async {
    widget.themes.forEach((theme) {
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
    setState(() {});
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
              uploadGameStats();
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('home');
            },
          ),
        ],
      ),
    );
  }

  void uploadGameStats() async {
    Firestore firestore = Firestore.instance;
    num mode = widget.mode;
    Map<String, num> time = t.timePlayed();
    num pointsScored = score;
    SharedPreferences preferences = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> imagesSwiped = new List();
    var username = preferences.getString("username");
    await firestore.collection('games').document().setData({
      'username': username,
      'mode': mode,
      'timeTaken': time,
      'pointsScored': pointsScored,
      'imagesSwiped': imagesSwiped,
    });
    if (swipes.length > 0) {
      Set<String> themeIdsSwiped = new Set<String>();
      widget.themes.forEach((th) {
        themeIdsSwiped.add(th.id);
      });
      List<GameTheme> themes = new List();
      Map<String, DocumentReference> docs = new Map();
      for (var th in themeIdsSwiped) {
        var sp = await firestore
            .collection('themes')
            .where('id', isEqualTo: th)
            .getDocuments();
        if (sp.documents.length > 0) {
          var doc = sp.documents.first;
          themes.add(new GameTheme.fromMap(doc.data));
          docs.addAll({
            doc.data['id']: doc.reference,
          });
        }
      }

      for (var s in swipes) {
        var themeIndex = themes.indexWhere((t) {
          return t.id == s.image.themeId;
        });
        themes[themeIndex].images[s.image.imgIndex].total += 1;
        themes[themeIndex].images[s.image.imgIndex].correct +=
            s.swipe == themes[themeIndex].images[s.image.imgIndex].type ? 1 : 0;
      }
      for (var th in themes) {
        List<Map<String, dynamic>> im = new List();
        for (var i in th.images) {
          im.add({
            'link': i.link,
            'correct': i.correct,
            'total': i.total,
            'type': i.type,
          });
        }
        await docs[th.id].updateData({'images': im});
      }
    }
  }

  void loadAudio() async {
    bgm.play("gameAudio.mp3");
  }

  void checkGameTutorialFinished() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    gameTutorialFinished = pref.getBool("gameTutorialFinished");
    if (gameTutorialFinished == null) {
      await pref.setBool("gameTutorialFinished", false);
      gameTutorialFinished = false;
    }
    setState(() {});
  }

  void startTutorial(BuildContext context) async {
    if (!gameTutorialFinished) {
      await Future.delayed(Duration(seconds: 2));
      ShowCaseWidget.of(context).startShowCase([_left, _right, _score, _time]);
    }
  }

  @override
  void initState() {
    super.initState();
    checkGameTutorialFinished();
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
      reverse: widget.mode == 0,
      initDuration: widget.mode == 0
          ? const Duration(
              seconds: 30,
            )
          : null,
      style: TextStyle(
        color: Colors.white,
        fontSize: 25,
      ),
      timerEnd: gameOver,
    );
    loadingDialog();
  }

  @override
  void dispose() {
    bgm.clearAll();
    flameAudio.clearAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageShow current = shownImages.last;
    var stack = new IndexedStack(
      index: loading ? 0 : 1,
      children: <Widget>[
        Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "LOADING YOUR GAME\n......",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.pink,
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 5,
                ),
              ),
              Image.asset("assets/loading.gif"),
            ],
          ),
        ),
        ShowCaseWidget(
          onFinish: () async {
            SharedPreferences pref = await SharedPreferences.getInstance();
            gameTutorialFinished = true;
            await pref.setBool("gameTutorialFinished", true);
          },
          builder: Builder(
            builder: (context) {
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
                      Spacer(
                        flex: 2,
                      ),
                      /* Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 12.0, right: 12.0, top: 40.0, bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              AutoSizeText(
                                "ELARE",
                                minFontSize: 50,
                                maxLines: 1,
                                maxFontSize: 60,
                                style: TextStyle(
                                  color: Colors.white,
                                  letterSpacing: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ), */
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                                  Expanded(
                                    child: AutoSizeText(
                                      "Lives:",
                                      minFontSize: 20,
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
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
                                    description:
                                        "Current Score. If score goes less than 0,\nthen game over!!",
                                  ),
                                ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 12.0, right: 12.0, top: 40.0, bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Showcase(
                                key: _time,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFff6e6e),
                                    borderRadius: BorderRadius.circular(20.0),
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
                                    (widget.mode == 0
                                        ? "\nTry to swipe as many\n images as possible\nwithin this time."
                                        : ""),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
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
                      ),
                      Expanded(
                        flex: 2,
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
                                      "If current Image is a ${current.type0},\nswipe left the image\nor Press this button",
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
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                    description:
                                        "If current Image is a ${current.type1}, \n swipe right the image \n or Press this button"),
                              ),
                              Spacer(
                                flex: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
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
