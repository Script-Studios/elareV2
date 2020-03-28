import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/dataClasses.dart';
import 'package:flutter_story_app_concept/newGame.dart';
import 'package:flutter_story_app_concept/signInPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:connectivity/connectivity.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Connectivity connectivity;
  List<GameTheme> themes = new List(), addedThemes = new List();
  Firestore firestore = Firestore.instance;
  bool homeTutorialFinished;
  GlobalKey _themeKey = new GlobalKey(), _startKey = new GlobalKey();
  bool noWifiDialogOpen = false;
  void getThemes() async {
    var sp = await firestore.collection('themes').getDocuments();
    for (var doc in sp.documents) {
      themes.add(new GameTheme.fromMap(doc.data));
    }
    setState(() {});
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
                ),
              ),
              Spacer(),
              Text(
                "ENDLESS",
                style: TextStyle(
                  color: Colors.white,
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
    if (!homeTutorialFinished) {
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
      isConnected = (result.isNotEmpty && result[0].rawAddress.isNotEmpty);
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

  @override
  void initState() {
    super.initState();
    connectivity = new Connectivity();
    connectivity.onConnectivityChanged.listen((res) async {
      print(res);
      if (await checkConnectivity()) {
        removeDialog();
        print("1");
      } else {
        print(2);
        notConnectedDialog();
      }
    });
    checkLogin();
    checkHomeTutorialFinished();
    getThemes();
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onFinish: () async {
        SharedPreferences pref = await SharedPreferences.getInstance();
        homeTutorialFinished = true;
        await pref.setBool("homeTutorialFinished", true);
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
                tileMode: TileMode.clamp,
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 12.0,
                      right: 12.0,
                      top: 40.0,
                      bottom: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          "ELARE",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 46.0,
                            letterSpacing: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 25,
                  ),
                  Container(
                    child: Text(
                      "Swipe Themes to Add",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 12.0,
                        right: 12.0,
                        top: 8.0,
                        bottom: 8.0,
                      ),
                      child: ListView.builder(
                        itemBuilder: (context, i) {
                          return Dismissible(
                            direction: DismissDirection.startToEnd,
                            onDismissed: (dir) {
                              addedThemes.add(themes.removeAt(i));
                              setState(() {});
                            },
                            key: new Key(themes[i].id),
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              height: 150,
                              child: LayoutBuilder(
                                builder: (c, con) {
                                  if (i == 0) {
                                    startTutorial(context);
                                    return Showcase(
                                      key: _themeKey,
                                      child: Stack(
                                        children: <Widget>[
                                          Container(
                                            height: 150,
                                            width: con.maxWidth,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                              child: CachedNetworkImage(
                                                imageUrl: themes[i].coverUrl,
                                                placeholder: (context, s) =>
                                                    Container(
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                  color: Colors.white,
                                                ),
                                                fit: BoxFit.fitWidth,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 20,
                                            left: (con.maxWidth - 150) / 2,
                                            right: (con.maxWidth - 150) / 2,
                                            child: Container(
                                              width: 250,
                                              child: AutoSizeText(
                                                themes[i].type0 +
                                                    " / " +
                                                    themes[i].type1,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      description: "Swipe Themes to add",
                                    );
                                  } else {
                                    return Stack(
                                      children: <Widget>[
                                        Container(
                                          height: 150,
                                          width: con.maxWidth,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20.0),
                                            child: CachedNetworkImage(
                                              imageUrl: themes[i].coverUrl,
                                              placeholder: (context, s) =>
                                                  Container(
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                                color: Colors.white,
                                              ),
                                              fit: BoxFit.fitWidth,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 20,
                                          left: (con.maxWidth - 150) / 2,
                                          right: (con.maxWidth - 150) / 2,
                                          child: Container(
                                            width: 250,
                                            child: AutoSizeText(
                                              themes[i].type0 +
                                                  " / " +
                                                  themes[i].type1,
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                              maxLines: 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        },
                        itemCount: themes.length,
                      ),
                    ),
                  ),
                  Showcase(
                    key: _startKey,
                    child: FlatButton(
                      onPressed: addedThemes.length > 0 ? startGame : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(20.0),
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
                            minFontSize: 20,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    description: "Start Game",
                  ),
                  AnimatedContainer(
                    curve: Curves.ease,
                    duration: Duration(milliseconds: 750),
                    child: Text(
                      addedThemes.length.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 20,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
