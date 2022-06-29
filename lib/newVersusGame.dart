import 'dart:async';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/cards.dart';
import 'package:flutter_story_app_concept/dataClasses.dart';
import 'package:flutter_story_app_concept/gameTimer.dart';
import 'package:flutter_story_app_concept/main.dart';
import 'package:flutter_story_app_concept/settingsPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animation_set/widget/transition_animations.dart';
import 'package:flutter_animation_set/widget/behavior_animations.dart';

class NewVersusGame extends StatefulWidget {
  final List<GameTheme> themes;
  String collId;
  final int mode; //0 for timed, 1 for endless
  List<ImageShow> images, shownImages;
  CardScrollWidget cards;
  final User me;
  final Friend f;
  NewVersusGame({
    @required this.themes,
    @required this.images,
    @required this.shownImages,
    @required this.mode,
    @required this.cards,
    @required this.collId,
    @required this.me,
    @required this.f,
  });
  @override
  _NewVersusGameState createState() =>
      new _NewVersusGameState(images, shownImages, cards);
}

var cardAspectRatio = 12.0 / 16.0;
var widgetAspectRatio = cardAspectRatio * 1.2;

class _NewVersusGameState extends State<NewVersusGame>
    with WidgetsBindingObserver {
  _NewVersusGameState(this.images, this.shownImages, this.cards);

  StreamSubscription gameStream;
  int initialLives = 3;
  GameTimer t, oppT;
  CounterWidget cnt;
  Connectivity connect;
  List<CardScrollWidget> themes;
  CardScrollWidget cards;
  List<ImageShow> images, shownImages;
  List<Swipe> swipes;
  int score = 0, oppScore = 0;
  bool gameTutorialFinished;
  bool loading = false;
  List<Widget> lives, lifeGone, oppLives, oppLifeGone;
  int imagesLoaded = 0;
  bool firstBackDone = false;
  Timer firstBackTimer;
  bool started = false, oppStarted = false;
  bool reverse = false;
  DocumentReference scoreRef, lifeRef;

  void saveTotalPoints() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String key = "mode${widget.mode}Score";
    int points = preferences.getInt(key);
    await preferences.setInt(key, score + points);
    await me.firebaseReference.updateData(
      {
        key: (score + points),
      },
    );
  }

  void swipeAudio() {
    playAudio("swipe.mp3");
  }

  void wrongSwipeAudio() {
    playAudio("wrongSwipe.mp3");
  }

  void gameOverAudio() async {
    playBgm("gameOver.mp3");
  }

  void updateScore() {
    scoreRef.updateData({
      'score': score,
      'created': DateTime.now().toLocal().toString(),
    });
  }

  void updateLife() {
    lifeRef.updateData({
      'life': lives.length,
      'created': DateTime.now().toLocal().toString(),
    });
  }

  void startTimer(bool opp) {
    if (opp) {
      if (!oppT.isActive()) oppT.startTimer();
    } else {
      if (!t.isActive()) t.startTimer();
      Firestore.instance.collection(widget.collId).document().setData({
        'type': 'startTimer',
        'username': widget.me.username,
        'created': DateTime.now().toLocal().toString(),
      });
    }
  }

  void removeImage(int swipe) {
    int counter = cnt.counter;
    counter = min(counter, 5);
    if (swipes.length == 0 && widget.mode == 1) startTimer(false);
    var current = shownImages.removeLast();
    int correctSwipe = current.image.type;
    if (widget.mode == 2 && reverse) {
      correctSwipe = 1 - correctSwipe;
    }
    if (swipe == correctSwipe) {
      score += 2 * counter;
      updateScore();
      scoreRef.updateData({'score': score});
    } else if (widget.mode != 1) {
      wrongSwipeAudio();
      lifeRemoved(initialLives - lives.length, false);
    }
    swipes.add(
      new Swipe(image: current, swipe: swipe),
    );
    if (images.length > 0) shownImages.insert(0, images.removeAt(0));

    if (lives.length == 0) {
      updateGameOver();
      gameOver();
    }
    if (widget.mode == 2) setReverse();
    cnt.reset();
    setState(() {});
  }

  void lifeRemoved(int i, bool opp) async {
    setState(() {
      if (opp) {
        oppLives.removeLast();
        oppLifeGone.add(
          Expanded(
            child: YYSingleLike(),
          ),
        );
      } else {
        lives.removeLast();
        lifeGone.add(
          Expanded(
            child: YYSingleLike(),
          ),
        );
      }
    });
    updateLife();
    await Future.delayed(Duration(milliseconds: 1500));
    setState(() {
      if (opp)
        oppLifeGone[i] = Spacer();
      else
        lifeGone[i] = Spacer();
    });
  }

  void subscribeGameCollection() {
    gameStream = Firestore.instance
        .collection(widget.collId)
        .snapshots()
        .listen(recievedSp);
  }

  void recievedSp(QuerySnapshot sp) {
    sp.documents.forEach((doc) {
      var d = doc.data;
      var date = DateTime.parse(d['created']), curr = DateTime.now();
      if (date.difference(curr).inSeconds < 10) {
        if (d['type'] == 'score') {
          if (d['username'].toString() != widget.me.username) {
            oppScore = int.parse(d['score'].toString());
          }
        } else if (d['type'] == 'life') {
          if (d['username'].toString() != widget.me.username) {
            int l = int.parse(d['life'].toString());
            if (l < oppLives.length) {
              for (int i = 0; i < oppLives.length - l; i++)
                lifeRemoved(initialLives - oppLives.length, true);
            }
          }
        } else if (d['type'] == 'start') {
          if (d['username'].toString() != widget.me.username) {
            oppStarted = true;
            if (started) {
              setState(() {});
            }
          }
        } else if (d['type'] == 'startTimer') {
          if (d['username'].toString() != widget.me.username) {
            startTimer(true);
          }
        } else if (d['type'] == 'gameover') {
          if (d['username'].toString() != widget.me.username) {
            gameOver();
          }
        }
      }
    });
  }

  void setRefs() async {
    scoreRef = Firestore.instance.collection(widget.collId).document();
    scoreRef.setData({
      'score': score,
      'type': 'score',
      'username': widget.me.username,
      'created': DateTime.now().toLocal().toString(),
    });
    lifeRef = Firestore.instance.collection(widget.collId).document();
    lifeRef.setData({
      'life': lives.length,
      'type': 'life',
      'username': widget.me.username,
      'created': DateTime.now().toLocal().toString(),
    });
  }

  void deleteCol() async {
    print("deleting Collection");
    var sp = await Firestore.instance.collection(widget.collId).getDocuments();
    sp.documents.forEach((doc) {
      doc.reference.delete();
    });
  }

  void updateGameOver() {
    Firestore.instance.collection(widget.collId).document().setData({
      'type': 'gameover',
      'username': widget.me.username,
      'created': DateTime.now().toLocal().toString(),
    });
  }

  void gameOver() {
    stopBgm();
    gameOverAudio();
    if (widget.mode == 1) t.endTimer();
    saveTotalPoints();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        child: AlertDialog(
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
                stopBgm();
                uploadGameStats();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('home', (route) => false);
              },
            ),
          ],
        ),
        onWillPop: () async {
          return false;
        },
      ),
    );
  }

  void uploadGameStats() async {
    Firestore firestore = Firestore.instance;
    num mode = widget.mode;
    Map<String, num> time;
    if (widget.mode == 1) time = t.timePlayed();
    num pointsScored = score;
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var username = preferences.getString("username");
    List<Map<String, dynamic>> imagesSwiped = new List();
    swipes.forEach((s) {
      Map<String, dynamic> m = new Map();
      m.addAll({
        'themeId': s.image.themeId,
        'imgIndex': s.image.imgIndex,
        'correct': s.swipe == s.image.image.type,
      });
      imagesSwiped.add(m);
    });
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
    try {
      playBgm(gameAudio);
    } catch (e) {
      print(e);
    }
  }

  void startGame() async {
    await Future.delayed(Duration(milliseconds: 500));
    started = true;
    Firestore.instance.collection(widget.collId).document().setData({
      'type': 'start',
      'username': widget.me.username,
      'created': DateTime.now().toLocal().toString(),
    });
    if (oppStarted) {
      setState(() {});
    }
  }

  void setReverse() {
    Random r = new Random();
    reverse = r.nextBool();
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
    cards.removeImage = removeImage;
    swipes = new List();
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
    oppLives = [
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
    lifeGone = new List<Widget>();
    oppLifeGone = new List<Widget>();
    subscribeGameCollection();
    setRefs();
    print("mode" + widget.mode.toString());
    if (widget.mode == 1) {
      t = new GameTimer(
        reverse: true,
        initDuration: const Duration(
          seconds: 30,
        ),
        style: TextStyle(
          color: Colors.white,
          fontSize: 25,
        ),
        timerEnd: gameOver,
      );
      oppT = new GameTimer(
        reverse: widget.mode == 1,
        initDuration: const Duration(
          seconds: 30,
        ),
        style: TextStyle(
          color: Colors.white,
          fontSize: 25,
        ),
        timerEnd: gameOver,
      );
    }
    cnt = new CounterWidget();
    loadAudio();
    if (widget.mode == 2) setReverse();
    startGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    gameStream.cancel();
    deleteCol();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageShow current = shownImages.last;
    var stack = new IndexedStack(
      index: started && oppStarted ? 1 : 0,
      children: <Widget>[
        Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                !started ? "LOADING YOUR GAME\n......" : "Waiting for Opponent",
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
                Spacer(),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: (widget.mode == 1
                              ? <Widget>[
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.only(
                                          left: 12.0,
                                          right: 12.0,
                                          top: 8.0,
                                          bottom: 8.0),
                                      width: MediaQuery.of(context).size.width -
                                          150,
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
                                  ),
                                ]
                              : lives + lifeGone.reversed.toList()) +
                          <Widget>[
                            Spacer(),
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 50,
                                width: MediaQuery.of(context).size.width - 150,
                                decoration: BoxDecoration(
                                  color: Color(0xFFff6e6e),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 22.0, vertical: 6.0),
                                    child: AutoSizeText(
                                      "$score",
                                      minFontSize: 25,
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Divider(
                        color: Colors.white,
                        thickness: 0.5,
                      ),
                    ),
                    Column(
                      children: <Widget>[
                        Text(
                          widget.me.username,
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "v/s",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.f.username,
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.white,
                        thickness: 0.5,
                      ),
                    )
                  ],
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: (widget.mode == 1
                              ? <Widget>[
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.only(
                                          left: 12.0,
                                          right: 12.0,
                                          top: 8.0,
                                          bottom: 8.0),
                                      width: MediaQuery.of(context).size.width -
                                          150,
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
                                          child: oppT,
                                        ),
                                      ),
                                    ),
                                  ),
                                ]
                              : oppLives + oppLifeGone.reversed.toList()) +
                          <Widget>[
                            Spacer(),
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 50,
                                width: MediaQuery.of(context).size.width - 150,
                                decoration: BoxDecoration(
                                  color: Color(0xFFff6e6e),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 22.0, vertical: 6.0),
                                    child: AutoSizeText(
                                      "$oppScore",
                                      minFontSize: 25,
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                    ),
                  ),
                ),
                Spacer(
                  flex: 1,
                ),
                Expanded(
                  flex: 13,
                  child: LayoutBuilder(
                    builder: (context, cons) {
                      return SizedBox(
                        child: Stack(
                          children: <Widget>[
                            cards,
                            Positioned(
                              left:
                                  cons.biggest.height * widgetAspectRatio / 2 -
                                      15,
                              bottom: 5,
                              child: cnt,
                            ),
                          ],
                        ),
                        height: cons.biggest.height,
                        width: cons.biggest.height * widgetAspectRatio,
                      );
                    },
                  ),
                ),
                Spacer(),
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
                          child: FlatButton(
                            onPressed: () {
                              swipeAudio();
                              cards.card.swipeLeft();
                            },
                            child: Container(
                              height: double.maxFinite,
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 22.0),
                                child: Center(
                                  child: AutoSizeText(
                                    widget.mode == 2 && reverse
                                        ? current.type1
                                        : current.type0,
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
                        ),
                        Spacer(
                          flex: 1,
                        ),
                        Expanded(
                          flex: 6,
                          child: FlatButton(
                            onPressed: () {
                              swipeAudio();
                              cards.card.swipeRight();
                            },
                            child: Container(
                              height: double.maxFinite,
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 22.0),
                                child: Center(
                                  child: AutoSizeText(
                                    widget.mode == 2 && reverse
                                        ? current.type0
                                        : current.type1,
                                    textAlign: TextAlign.center,
                                    minFontSize: 22,
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                    maxLines: 5,
                                    wrapWords: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                ),
                Spacer(
                  flex: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
    return WillPopScope(
        child: AnimatedOpacity(
          opacity: 1,
          duration: Duration(milliseconds: 500),
          child: stack,
        ),
        onWillPop: () async {
          /* if (firstBackDone &&
              (firstBackTimer != null && firstBackTimer.isActive)) {
            bgm.stop();
            gameOverAudio();
            gameOver();
          } else {
            firstBackTimer.cancel();
            firstBackTimer = new Timer(Duration(seconds: 4), () {
              firstBackDone = false;
            });
            firstBackDone = true;
            Fluttertoast.showToast(msg: "Press Back again to stop the game...");
          } */
          return false;
        });
  }
}
