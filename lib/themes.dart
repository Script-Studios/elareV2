import 'dart:async';
import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/dataClasses.dart';
import 'package:flutter_story_app_concept/newGame.dart';
import 'package:flutter_story_app_concept/settingsPage.dart';
import 'package:flutter_story_app_concept/signInPage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:connectivity/connectivity.dart';
import 'package:path_provider/path_provider.dart';

class ThemeSelection extends StatefulWidget {
  @override
  _ThemeSelectionState createState() => _ThemeSelectionState();
}

class _ThemeSelectionState extends State<ThemeSelection> {
  Connectivity connectivity;
  List<GameTheme> themes = new List(), addedThemes = new List();
  Firestore firestore = Firestore.instance;
  bool homeTutorialFinished;
  GlobalKey _themeKey = new GlobalKey(), _startKey = new GlobalKey();
  bool noWifiDialogOpen = false;
  PageController controller;
  bool openSettings = false;
  bool firstBack = false;
  Timer backTimer;
  bool themeLoading = false;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  GameTheme moveTheme;
  bool moving = false, showAddedTheme = false;

  void saveThemeCover(Map<String, String> data) async {
    print(data);
    FirebaseStorage firebaseStorage = FirebaseStorage.instance;
    final Directory appDirectory = await getApplicationDocumentsDirectory();
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final String pictureDirectory = '${appDirectory.path}/Pictures';
    await Directory(pictureDirectory).create(recursive: true);
    data.forEach((id, url) async {
      var ref = await firebaseStorage.getReferenceFromUrl(url);
      var dataBytes = await ref.getData(1024 * 1024);
      var imagePath = '$pictureDirectory/$id.png';
      File f = new File(imagePath);
      await f.writeAsBytes(dataBytes);
      await preferences.setString(id, imagePath);
    });
  }

  void getThemes() async {
    setState(() {
      themeLoading = true;
    });
    SharedPreferences preferences = await SharedPreferences.getInstance();
    themes = new List();
    Map<String, String> data = new Map();
    var sp = await firestore.collection('themes').getDocuments();
    for (var doc in sp.documents) {
      var loc = preferences.getString(doc.data['id']);
      if (loc == null) {
        data.addAll({
          doc.data['id']: doc.data['cover'],
        });
      } else {
        print("Downloaded");
      }
      setState(() {
        themes.add(new GameTheme.fromMap(doc.data, location: loc));
        themeLoading = false;
      });
    }
    saveThemeCover(data);
  }

  void startGame() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dismissible(
        key: new Key("startGame"),
        onDismissed: (dir) {
          Navigator.pop(context);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => NewGame(
                themes: addedThemes,
                mode: dir == DismissDirection.startToEnd ? 1 : 0,
                cards: null,
                images: null,
                shownImages: null,
              ),
            ),
          );
        },
        child: AlertDialog(
          backgroundColor: Color(0xFF1b1e44 + 0xFF2d3447),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "SWIPE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                ),
              ),
            ],
          ),
          content: Row(
            children: <Widget>[
              Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              Text(
                "TIMED",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
              Spacer(),
              Text(
                "ENDLESS",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void checkLogin() async {
    FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    var user = await firebaseAuth.currentUser();
    if (user == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SignInPage(),
      );
    }
  }

  void checkHomeTutorialFinished() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    homeTutorialFinished = pref.getBool("homeTutorialFinished");
    if (homeTutorialFinished == null) {
      await pref.setBool("homeTutorialFinished", false);
      homeTutorialFinished = false;
    }
    setState(() {});
  }

  void startTutorial(BuildContext context) async {
    await Future.delayed(Duration(seconds: 1));
    if (homeTutorialFinished) {
      ShowCaseWidget.of(context).startShowCase([_themeKey, _startKey]);
    }
  }

  Future<bool> checkConnectivity() async {
    var res = await connectivity.checkConnectivity();
    bool isConnected = res != ConnectivityResult.none;
    if (res == ConnectivityResult.mobile || res == ConnectivityResult.wifi) {
      var result =
          await InternetAddress.lookup("www.google.com").catchError((e) {
        print(e);
      });
      isConnected = (result != null &&
          result.isNotEmpty &&
          result[0].rawAddress.isNotEmpty);
    }
    return isConnected;
  }

  void notConnectedDialog() {
    noWifiDialogOpen = true;
    var ad = WillPopScope(
      child: AlertDialog(
        backgroundColor: Color(0xff252525),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              "No Internet Connected!",
              style: TextStyle(
                fontSize: 20,
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            Image.asset("assets/wifi.gif"),
          ],
        ),
      ),
      onWillPop: () async {
        return false;
      },
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ad,
    );
  }

  void removeDialog() {
    if (noWifiDialogOpen) {
      noWifiDialogOpen = false;
      Navigator.of(context).pop();
    }
  }

  void move() async {
    await Future.delayed(const Duration(milliseconds: 250));
    setState(() {
      moving = true;
    });
    await Future.delayed(Duration(milliseconds: 750));
    setState(() {
      moving = false;
      moveTheme = null;
    });
  }

  @override
  void initState() {
    super.initState();
    controller = new PageController();
    connectivity = new Connectivity();
    connectivity.onConnectivityChanged.listen((res) async {
      if (await checkConnectivity()) {
        removeDialog();
      } else {
        notConnectedDialog();
      }
    });
    //checkLogin();
    checkHomeTutorialFinished();
    getThemes();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      pageSnapping: false,
      itemCount: openSettings ? 2 : 1,
      onPageChanged: (i) async {
        if (i == 0) {
          await controller.animateToPage(
            0,
            duration: const Duration(milliseconds: 750),
            curve: Curves.ease,
          );
          setState(() {
            openSettings = false;
          });
        }
      },
      itemBuilder: (context, i) {
        if (i == 0) {
          return WillPopScope(
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xff081c36),
              ),
              child: Scaffold(
                key: scaffoldKey,
                backgroundColor: Colors.transparent,
                body: Column(
                  children: <Widget>[
                    Spacer(
                      flex: 1,
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "ELARE",
                        style: TextStyle(
                          color: Color(0xff8d9db1),
                          fontSize: 60.0,
                          letterSpacing: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Spacer(
                      flex: 1,
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Spacer(),
                          Expanded(
                            flex: 2,
                            child: Container(
                              child: Text(
                                "Swipe Themes to Add",
                                style: TextStyle(
                                    color: Color(0xff8d9db1), fontSize: 30),
                              ),
                            ),
                          ),
                          Expanded(
                            child: IconButton(
                              icon: Icon(
                                Icons.settings,
                                color: Color(0xff8d9db1),
                              ),
                              onPressed: () {
                                setState(() {
                                  openSettings = true;
                                });
                                controller.animateTo(
                                  250,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.ease,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      overflow: Overflow.clip,
                      children: <Widget>[
                            themeLoading
                                ? Positioned(
                                    top: MediaQuery.of(context).size.height / 3,
                                    left: MediaQuery.of(context).size.width / 2,
                                    child: CircularProgressIndicator(),
                                  )
                                : SizedBox(),
                            Container(
                              height: MediaQuery.of(context).size.height / 1.4,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemBuilder: (context, i) {
                                  return Dismissible(
                                    direction: openSettings
                                        ? null
                                        : DismissDirection.startToEnd,
                                    onDismissed: (dir) {
                                      moveTheme = themes.removeAt(i);
                                      addedThemes.add(moveTheme);
                                      setState(() {});
                                      move();
                                    },
                                    key: new Key(themes[i].id),
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 20,
                                      ),
                                      height: 150,
                                      child: LayoutBuilder(
                                        builder: (c, con) {
                                          startTutorial(context);
                                          return Stack(
                                            children: <Widget>[
                                              Container(
                                                height: 150,
                                                width: con.maxWidth,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20.0),
                                                  child: themes[i].loc != null
                                                      ? Image.file(
                                                          File(
                                                            themes[i].loc,
                                                          ),
                                                          fit: BoxFit.fitWidth,
                                                        )
                                                      : CachedNetworkImage(
                                                          imageUrl: themes[i]
                                                              .coverUrl,
                                                          placeholder:
                                                              (context, s) =>
                                                                  Container(
                                                            child: Center(
                                                              child:
                                                                  CircularProgressIndicator(),
                                                            ),
                                                            color: Color(
                                                                0xffff5c48),
                                                          ),
                                                          fit: BoxFit.fitWidth,
                                                        ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 10,
                                                left: (con.maxWidth - 150) / 2,
                                                right: (con.maxWidth - 150) / 2,
                                                child: Container(
                                                  padding: EdgeInsets.all(3),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.0),
                                                    color: Color(0xffff5c48),
                                                  ),
                                                  width: 250,
                                                  child: AutoSizeText(
                                                    themes[i].type0 +
                                                        " / " +
                                                        themes[i].type1,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                    maxLines: 1,
                                                    minFontSize: 20,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                                itemCount: themes.length,
                              ),
                            ),
                            AnimatedPositioned(
                              bottom: addedThemes.length > 0 ? 30.0 : -100,
                              left: MediaQuery.of(context).size.width / 2 - 90,
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    child: FlatButton(
                                      onPressed: addedThemes.length > 0
                                          ? startGame
                                          : null,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Color(0xffff5c48),
                                          borderRadius:
                                              BorderRadius.circular(20.0),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 22.0, vertical: 6.0),
                                          child: AutoSizeText(
                                            "Start Game",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                            minFontSize: 25,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xffff5c48),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    padding: EdgeInsets.all(5),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.subject,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          showAddedTheme = !showAddedTheme;
                                        });
                                      },
                                      color: Colors.white,
                                    ),
                                  )
                                ],
                              ),
                              duration: Duration(milliseconds: 500),
                            ),
                            showAddedTheme
                                ? Positioned(
                                    bottom: 100,
                                    left: MediaQuery.of(context).size.width / 2,
                                    child: Container(
                                      height: 150,
                                      width: 150,
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Color(0xffff5c48),
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                        border: Border.all(width: 1.0),
                                      ),
                                      child: ListView.builder(
                                        itemCount: addedThemes.length,
                                        itemBuilder: (context, i) {
                                          return Container(
                                            padding: EdgeInsets.all(2),
                                            width: 137,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: <Widget>[
                                                Container(
                                                  height: 80,
                                                  width: 85,
                                                  child: ClipRRect(
                                                    child: CachedNetworkImage(
                                                      imageUrl: addedThemes[i]
                                                          .coverUrl,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.cancel,
                                                    size: 20,
                                                    color: Colors.white,
                                                  ),
                                                  onPressed: () {
                                                    themes.insert(
                                                        0,
                                                        addedThemes
                                                            .removeAt(i));
                                                    if (addedThemes.isEmpty)
                                                      showAddedTheme = false;
                                                    setState(() {});
                                                  },
                                                )
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  )
                                : SizedBox(),
                          ] +
                          (moveTheme != null
                              ? [
                                  AnimatedPositioned(
                                    bottom: moving
                                        ? 30.0
                                        : MediaQuery.of(context).size.height /
                                            3,
                                    left: moving
                                        ? MediaQuery.of(context).size.width /
                                                2 +
                                            80
                                        : MediaQuery.of(context).size.width /
                                                2 +
                                            50,
                                    child: Container(
                                      height: 60,
                                      width: 60,
                                      decoration: BoxDecoration(
                                        color: Color(0xffff5c48),
                                        border: Border.all(width: 1.0),
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                      ),
                                      padding: EdgeInsets.all(2),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: CachedNetworkImage(
                                          imageUrl: moveTheme.coverUrl,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    duration: Duration(milliseconds: 750),
                                  ),
                                ]
                              : showAddedTheme ? [] : []),
                    ),
                  ],
                ),
              ),
            ),
            onWillPop: () async {
              if (firstBack) {
                return true;
              } else {
                firstBack = true;
                if (backTimer != null && backTimer.isActive) {
                  backTimer.cancel();
                }
                backTimer = new Timer(
                  const Duration(seconds: 4),
                  () {
                    firstBack = false;
                  },
                );
                Fluttertoast.showToast(
                  msg: "Press back again to exit",
                  gravity: ToastGravity.BOTTOM,
                  toastLength: Toast.LENGTH_SHORT,
                );
                return false;
              }
            },
          );
        } else {
          return null;
        }
      },
    );
  }
}
