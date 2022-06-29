import 'dart:async';
import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_story_app_concept/cards.dart';
import 'package:flutter_story_app_concept/main.dart';
import 'package:flutter_story_app_concept/newGame.dart';
import 'package:flutter_story_app_concept/newVersusGame.dart';
import 'package:flutter_story_app_concept/selectThemes.dart';
import 'package:flutter_story_app_concept/settingsPage.dart';
import 'package:flutter_story_app_concept/versusPage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/dataClasses.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var widgetAspectRatio = (12.0 / 16.0) * 1.2;
  int mode;
  CardScrollWidget cards;
  List<ImageShow> images, shownImages;
  List<String> imageLoc = [
    "assets/endless.jpg",
    "assets/timed.png",
    "assets/random.png",
  ],
      imageName = [
    "EndLess",
    "Timed",
    "Random",
  ];
  bool themeLoading = false;
  List<GameTheme> themes, selThemes;
  bool openSettings = false;
  PageController controller;
  bool firstBack = false;
  Timer backTimer;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription requestStream;
  Friend hostFriend;
  List<ProfilePicData> profilePics;
  bool requestPending = false;
  Timer requestTimer;
  bool starting = false;

  Future<void> getProfilePics() async {
    profilePics = new List();
    Firestore firestore = Firestore.instance;
    var sp = await firestore.collection('profilePic').getDocuments();
    sp.documents.forEach((d) {
      profilePics.add(new ProfilePicData.fromMap(d.data));
    });
  }

  Future<void> getMe() async {
    await getProfilePics();
    Firestore firestore = Firestore.instance;

    SharedPreferences preferences = await SharedPreferences.getInstance();
    var username = preferences.getString("username"),
        profile = preferences.getString("profilepic"),
        email = preferences.getString('email'),
        city = preferences.getString('city'),
        state = preferences.getString('state'),
        gender = preferences.getString('gender'),
        age = preferences.getInt('age');
    List<int> scores = new List();
    for (int i = 0; i < 3; i++) {
      String key = "mode${i}Score";
      int n = preferences.getInt(key);
      if (n == null) {
        n = 0;
        await preferences.setInt(key, n);
      }
      scores.add(n);
    }
    var sp = await firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .getDocuments();
    DocumentReference ref;
    if (sp.documents.length > 0) {
      ref = sp.documents.first.reference;
    }
    ProfilePicData pf = profilePics.firstWhere((p) => p.id == profile);
    me = new User(
      age: age,
      city: city,
      email: email,
      gender: gender,
      profile: pf,
      state: state,
      username: username,
      firebaseReference: ref,
      scores: scores,
    );
    setState(() {});
  }

  void subscribeRequestStream() async {
    await getMe();
    requestStream =
        Firestore.instance.collection('requests').snapshots().listen((sp) {
      sp.documents.forEach((doc) {
        var d = doc.data;
        var date = DateTime.parse(d['created']), curr = DateTime.now();
        if (date.difference(curr).inSeconds < 10) {
          if (me.username == d['friend'] &&
              d['status'] == 'req' &&
              !requestPending) {
            requestTimerStart();
            requestDialog(doc.reference, d);
          }
        }
      });
    });
  }

  void requestTimerStart() {
    requestTimer = Timer(Duration(seconds: 30), () {
      requestPending = false;
      Navigator.of(context).pop();
    });
  }

  void requestDialog(
      DocumentReference requestDocument, Map<String, dynamic> d) {
    requestPending = true;
    String username = d['host'], profile = d['hostProfile'];
    ProfilePicData pf = profilePics.firstWhere((p) => p.id == profile);
    Friend f = new Friend(
      profile: pf,
      ref: requestDocument,
      username: username,
    );
    void accept() {
      requestTimer.cancel();
      requestDocument.updateData({'status': 'acc'});
      requestPending = false;
      Fluttertoast.showToast(msg: "Challenge Accepted");
      Navigator.of(context).pop();
      acceptRequest(f, d);
    }

    void reject() {
      requestTimer.cancel();
      requestDocument.updateData({'status': 'rej'});
      requestPending = false;
      Fluttertoast.showToast(msg: "Challenge Rejected");
      Navigator.of(context).pop();
    }

    int mode1 = int.parse(d['mode'].toString());
    List<GameTheme> selThemes1 = new List.generate(d['themes'].length, (i) {
      return themes.firstWhere((t) {
        return t.id == d['themes'][i];
      });
    });
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            title: Text(
              "$username is challenging you for a game...",
              style: TextStyle(
                fontSize: 25,
              ),
            ),
            content: SingleChildScrollView(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.asset(
                            imageLoc[mode1],
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Text(
                        ":",
                        style: TextStyle(fontSize: 25),
                      ),
                    ] +
                    List.generate(selThemes1.length, (i) {
                      return Container(
                        height: 75,
                        width: 75,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: CachedNetworkImage(
                            imageUrl: selThemes1[i].coverUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    }),
              ),
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: reject,
                child: Text("Reject"),
              ),
              FlatButton(
                onPressed: accept,
                child: Text("Accept"),
              ),
            ],
          );
        });
  }

  void acceptRequest(Friend f, Map<String, dynamic> d) {
    String collId = f.username + "GAME" + me.username;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return WillPopScope(
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              content: Text("Loading Your Game...."),
            ),
            onWillPop: () async {
              return false;
            },
          );
        });
    CardScrollWidget cards1;
    int mode1 = int.parse(d['mode'].toString());
    List<ImageShow> images1 = new List(), shownImages1 = new List();
    List<GameTheme> selThemes1 = new List.generate(d['themes'].length, (i) {
      return themes.firstWhere((t) {
        return t.id == d['themes'][i];
      });
    });
    selThemes1.forEach((theme) {
      theme.images.forEach((image) {
        images1.add(
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
    images1.shuffle();
    for (int i = 0; i < 6; i++) {
      shownImages1.add(images1.removeAt(i));
    }
    cards1 = new CardScrollWidget(
      null,
      shownImages1,
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => NewVersusGame(
          themes: selThemes1,
          images: images1,
          shownImages: shownImages1,
          mode: mode1,
          cards: cards1,
          collId: collId,
          me: me,
          f: f,
        ),
      ),
      (route) => false,
    );
  }

  void versusMode() {
    scaffoldKey.currentState.showBottomSheet(
      (context) {
        return VersusPage(
          selThemes: selThemes,
          images: images,
          shownImages: shownImages,
          mode: mode,
          cards: cards,
          me: me,
        );
      },
      elevation: 30,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.0),
        ),
      ),
    );
  }

  void saveMode() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setInt("mode", mode);
  }

  void getMode() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      mode = preferences.getInt("mode");
    });
  }

  void getThemes() async {
    setState(() {
      themeLoading = true;
    });
    Firestore firestore = Firestore.instance;
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
      }
      themes.add(new GameTheme.fromMap(doc.data, location: loc));
    }
    saveThemeCover(data);
    var list = preferences.getStringList("selectedThemes");
    if (list == null) {
      await preferences.setStringList("selectedThemes", ['BYGL']);
      list = ['BYGL'];
    }
    selThemes = list.map<GameTheme>((s) {
      return themes.firstWhere((th) {
        return th.id == s;
      });
    }).toList();
    if (selThemes.length > 0) {
      getImages();
    }
    setState(() {
      themeLoading = false;
    });
  }

  void saveThemeCover(Map<String, String> data) async {
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

  void getImages() async {
    setState(() {
      themeLoading = true;
    });
    images = new List();
    shownImages = new List();
    selThemes.forEach((theme) {
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
    /* images.sort((im1, im2) {
      if (im1.image.correct < im2.image.correct)
        return 1;
      else if (im1.image.correct == im2.image.correct)
        return 0;
      else
        return -1;
    }); */
    images.shuffle();
    for (int i = 0; i < 6; i++) {
      shownImages.add(images.removeAt(i));
    }
    SharedPreferences preferences = await SharedPreferences.getInstance();
    List<String> selected = selThemes.map<String>((th) => th.id).toList();
    await preferences.setStringList("selectedThemes", selected);
    setState(() {
      themeLoading = false;
    });
  }

  void startGame() async {
    if (mode != null) {
      setState(() {
        starting = true;
      });
      await Future.delayed(Duration(milliseconds: 500));
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NewGame(
            themes: mode == 2 ? themes : selThemes,
            mode: mode,
            cards: cards,
            images: images,
            shownImages: shownImages,
          ),
        ),
      );
    } else {
      Fluttertoast.showToast(msg: "Please select a mode");
    }
  }

  void closeSettings() async {
    await controller.animateTo(
      0.0,
      duration: const Duration(milliseconds: 1250),
      curve: Curves.ease,
    );
    setState(() {
      openSettings = false;
    });
  }

  void checkUpdate() async {
    await Future.delayed(Duration());
    Firestore firestore = Firestore.instance;
    var sp = await firestore.collection('version').getDocuments();
    if (sp.documents.length == 1) {
      var d = sp.documents.first.data;
      String version = d['id'], link = d['link'], content = d['content'];
      if (version != "1.0.0+3") {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return WillPopScope(
              child: AlertDialog(
                backgroundColor: Color(0xFF1b1e44 + 0xFF2d3447),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "New Version Available!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  content != null
                      ? content
                      : "Check out our latest themes and stay updated!!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                actions: <Widget>[
                  FlatButton(
                    onPressed: () {
                      launch(link);
                    },
                    child: Text(
                      "Update",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
              onWillPop: () async {
                return false;
              },
            );
          },
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    subscribeRequestStream();
    themes = new List();
    selThemes = new List();
    getThemes();
    getMode();
    checkUpdate();
    controller = new PageController();
  }

  @override
  void dispose() {
    if (requestStream != null) requestStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: starting ? 0 : 1,
      duration: Duration(milliseconds: 500),
      child: PageView.builder(
        controller: controller,
        pageSnapping: true,
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
            cards = new CardScrollWidget(
              null,
              shownImages,
            );
            return WillPopScope(
              child: Scaffold(
                key: scaffoldKey,
                backgroundColor: Color(0xff081c36),
                body: Column(
                  children: <Widget>[
                    Spacer(
                      flex: 1,
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: <Widget>[
                          Spacer(
                            flex: 3,
                          ),
                          Expanded(
                            flex: 3,
                            child: AutoSizeText(
                              "ELARE",
                              style: TextStyle(
                                color: Color(0xff8d9db1),
                                letterSpacing: 8,
                                fontWeight: FontWeight.w500,
                              ),
                              minFontSize:
                                  MediaQuery.of(context).size.width / (3 * 2.5),
                              maxLines: 1,
                            ),
                          ),
                          Spacer(),
                          Expanded(
                            flex: 2,
                            child: IconButton(
                              icon: Icon(
                                Icons.settings,
                                color: Color(0xff8d9db1),
                              ),
                              onPressed: me == null
                                  ? () {
                                      Fluttertoast.showToast(msg: "Loading...");
                                    }
                                  : () {
                                      if (openSettings) {
                                        controller
                                            .animateTo(
                                          0,
                                          duration:
                                              const Duration(milliseconds: 500),
                                          curve: Curves.ease,
                                        )
                                            .then((_) {
                                          setState(() {
                                            openSettings = false;
                                          });
                                        });
                                      } else {
                                        setState(() {
                                          openSettings = true;
                                        });
                                        controller.animateToPage(
                                          1,
                                          duration: const Duration(
                                              milliseconds: 1000),
                                          curve: Curves.ease,
                                        );
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: themeLoading || selThemes.length == 0
                          ? Center(
                              child: SizedBox(
                                height: 25,
                                width: 25,
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, cons) {
                                var width =
                                    cons.biggest.height * widgetAspectRatio;
                                if (width > cons.biggest.width)
                                  width = cons.biggest.width;
                                return Stack(
                                  children: <Widget>[
                                    IgnorePointer(
                                      ignoring: true,
                                      child: Center(
                                        child: Opacity(
                                          opacity: 0.25,
                                          child: Container(
                                            child: cards,
                                            height: cons.biggest.height,
                                            width: width,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: TapToStartButton(startGame),
                                    )
                                  ],
                                );
                              },
                            ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: new List<Widget>.generate(3, (i) {
                          return Column(
                            children: <Widget>[
                              Expanded(
                                flex: 6,
                                child: GestureDetector(
                                  child: Container(
                                    height: 75,
                                    width: 75,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color: mode != null && mode == i
                                            ? Colors.green
                                            : Colors.white,
                                        width: 5.0,
                                      ),
                                    ),
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 5),
                                    child: Container(
                                      padding: EdgeInsets.all(5),
                                      child: Image.asset(
                                        imageLoc[i],
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      mode = i;
                                    });
                                    saveMode();
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  imageName[i],
                                  style: TextStyle(
                                    color: mode != null && mode == i
                                        ? Colors.green
                                        : Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (me == null) {
                            Fluttertoast.showToast(msg: "Loading...");
                          } else if (mode == null) {
                            Fluttertoast.showToast(msg: "Please select a mode");
                          } else {
                            versusMode();
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 10),
                          width: MediaQuery.of(context).size.width / 2,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(2),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(100),
                                    child: me != null
                                        ? CachedNetworkImage(
                                            imageUrl: me.profile.link,
                                            fit: BoxFit.contain,
                                          )
                                        : Image.asset(
                                            "assets/userAccount.jpg",
                                            fit: BoxFit.contain,
                                          ),
                                  ),
                                ),
                              ),
                              Text(
                                "v/s",
                                style: TextStyle(
                                  fontSize: 22,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(2),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(100),
                                    child: Image.asset(
                                      "assets/userAccount.jpg",
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          Spacer(),
                          Expanded(
                            flex: 4,
                            child: GestureDetector(
                              onTap: themeLoading
                                  ? () {
                                      Fluttertoast.showToast(msg: "Loading...");
                                    }
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => SelectThemes(
                                              themes, selThemes, getImages),
                                        ),
                                      );
                                    },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25.0),
                                  color: Color(0xff8d9db1),
                                ),
                                height: double.maxFinite,
                                width: MediaQuery.of(context).size.width - 80,
                                margin: EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Spacer(
                                      flex: 2,
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: AutoSizeText(
                                        "Select Themes",
                                        style: TextStyle(
                                          color: themeLoading
                                              ? Colors.grey[300]
                                              : Colors.black,
                                        ),
                                        minFontSize: 25,
                                      ),
                                    ),
                                    Expanded(
                                      child: Icon(
                                        Icons.arrow_forward,
                                        color: themeLoading
                                            ? Colors.grey[300]
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Spacer(),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              ),
              onWillPop: () async {
                if (firstBack) {
                  SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                  return false;
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
          } else if (i == 1) {
            return WillPopScope(
                child: SettingsPage(closeSettings, me, profilePics),
                onWillPop: () async {
                  await controller.animateTo(
                    0.0,
                    duration: const Duration(milliseconds: 1250),
                    curve: Curves.ease,
                  );
                  setState(() {
                    openSettings = false;
                  });
                  return false;
                });
          } else {
            return null;
          }
        },
      ),
    );
  }
}

class TapToStartButton extends StatefulWidget {
  final Function start;
  TapToStartButton(this.start);
  @override
  _TapToStartButtonState createState() => _TapToStartButtonState();
}

class _TapToStartButtonState extends State<TapToStartButton> {
  Timer t;
  bool op = true;

  @override
  void initState() {
    super.initState();
    t = new Timer.periodic(Duration(milliseconds: 750), (t) {
      op = !op;
      if (this.mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.start,
      child: Container(
        height: 50,
        width: 200,
        decoration: BoxDecoration(
          color: Color(0xff8d9db1),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Center(
          child: AnimatedOpacity(
            opacity: op ? 0 : 1,
            duration: Duration(milliseconds: 1000),
            child: Text(
              "Tap to Start.....",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
//Loading GIF Container, could be used later, if needed
/* Container(
                              width: MediaQuery.of(context).size.width - 50,
                              margin: EdgeInsets.all(
                                  ((MediaQuery.of(context).size.height - 10) *
                                      4 *
                                      0.3 /
                                      12)),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    "LOADING...",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.pink,
                                      fontSize: 35,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 5,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Image.asset(
                                      "assets/loading.gif",
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ) */
