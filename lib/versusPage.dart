import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/cards.dart';
import 'package:flutter_story_app_concept/dataClasses.dart';
import 'package:flutter_story_app_concept/newVersusGame.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_story_app_concept/settingsPage.dart';

class VersusPage extends StatefulWidget {
  List<ImageShow> images, shownImages;
  final List<GameTheme> selThemes;
  final int mode;
  CardScrollWidget cards;
  User me;
  VersusPage({
    @required this.images,
    @required this.shownImages,
    @required this.me,
    @required this.selThemes,
    @required this.mode,
    @required this.cards,
  });
  @override
  _VersusPageState createState() => _VersusPageState(me: me);
}

class _VersusPageState extends State<VersusPage> with TickerProviderStateMixin {
  bool globalLoading = true, friendLoading = true, gameLoading = false;
  List<Friend> globalUsers, friends;
  Friend requestedFriend;
  User me;
  List<String> gameThemes;
  DocumentReference requestRef;
  List<ProfilePicData> profilePics;
  StreamSubscription challengeStream, f1, f2, g1, gameStream;
  Timer t;
  TabController controller;
  int currIndex = 0;

  _VersusPageState({@required this.me});

  //Common

  Future<void> getProfilePics() async {
    profilePics = new List();
    Firestore firestore = Firestore.instance;
    var sp = await firestore.collection('profilePic').getDocuments();
    sp.documents.forEach((d) {
      profilePics.add(new ProfilePicData.fromMap(d.data));
    });
    getGlobalUsers();
    getFriends();
  }

  //Friends Tab

  void generateThemes() {
    widget.selThemes.forEach((t) {
      gameThemes.add(t.id);
    });
  }

  Future<void> getFriends() async {
    friends = new List();
    Firestore firestore = Firestore.instance;
    var sp = await firestore
        .collection('friends')
        .where("f1", isEqualTo: me.username)
        .getDocuments();
    sp.documents.forEach((doc) {
      addFriend(doc, 2);
    });
    sp = await firestore
        .collection('friends')
        .where("f2", isEqualTo: me.username)
        .getDocuments();
    sp.documents.forEach((doc) {
      addFriend(doc, 1);
    });
    setState(() {
      friendLoading = false;
    });
    f1 = firestore
        .collection('friends')
        .where("f1", isEqualTo: me.username)
        .snapshots()
        .listen((sp) {
      sp.documents.forEach((doc) {
        addFriend(doc, 2);
      });
    });
    f2 = firestore
        .collection('friends')
        .where("f2", isEqualTo: me.username)
        .snapshots()
        .listen((sp) {
      sp.documents.forEach((doc) {
        addFriend(doc, 1);
      });
    });
  }

  void addFriend(DocumentSnapshot doc, int mode) {
    var d = doc.data;
    String name, profile, status = d['status'];
    if (mode == 1) {
      name = d['f1'];
      profile = d['f1Prof'];
    } else if (mode == 2) {
      name = d['f2'];
      profile = d['f2Prof'];
    }
    if (!(friends.any(
      (f) {
        return f.username == name;
      },
    ))) {
      Friend f = new Friend();
      ProfilePicData pf = profilePics.firstWhere((p) => p.id == profile);
      f.username = name;
      f.profile = pf;
      if (status == 'req') {
        if (mode == 1) {
          f.isFriend = 'tobeAccepted';
        } else {
          f.isFriend = 'requested';
        }
      } else if (status == 'acc') {
        f.isFriend = "yes";
      }
      f.ref = doc.reference;
      friends.add(f);
      globalUsers.removeWhere(
        (f) {
          return f.username == name;
        },
      );
      setState(() {
        friendLoading = false;
      });
    }
  }

  void acceptRequest(Friend f) async {
    f.ref.updateData({'status': 'acc'});
  }

  void rejectRequest(Friend f) {
    f.ref.delete();
  }

  void challengeUser(Friend f) {
    setState(() {
      friendLoading = true;
    });
    requestedFriend = f;
    Firestore firestore = Firestore.instance;
    requestRef = firestore.collection('requests').document();
    requestRef.setData({
      'host': me.username,
      'friend': f.username,
      'status': 'req',
      'hostProfile': widget.me.profile.id,
      'themes': gameThemes,
      'mode': widget.mode,
      'created': DateTime.now().toLocal().toString(),
    }).then((_) {
      requestTimer();
    });
    challengeStream.resume();
  }

  void requestTimer() {
    t = Timer(Duration(seconds: 30), () {
      if (this.mounted) {
        Fluttertoast.showToast(msg: "Request Timed Out");
        challengeStream.pause();
        deleteChallengeref();
        setState(() {
          requestedFriend = null;
          friendLoading = false;
        });
      }
    });
  }

  void subscribeRequestStream() async {
    challengeStream =
        Firestore.instance.collection('requests').snapshots().listen((sp) {
      sp.documents.forEach((doc) {
        var d = doc.data;
        if (requestedFriend != null &&
            requestedFriend.username == d['friend'] &&
            me.username == d['host']) {
          if (d['status'] == 'acc') {
            challengeAccepted();
          } else if (d['status'] == 'rej') {
            challengeRejected();
          }
        }
      });
    });
  }

  void deleteChallengeref() {
    requestRef.delete();
  }

  void challengeAccepted() {
    Fluttertoast.showToast(msg: "${requestedFriend.username} accepted!!!");
    challengeStream.pause();
    deleteChallengeref();
    startGame();
    setState(() {
      friendLoading = false;
      gameLoading = true;
    });
  }

  void challengeRejected() {
    Fluttertoast.showToast(msg: "${requestedFriend.username} rejected!!!");
    challengeStream.pause();
    deleteChallengeref();
    setState(() {
      requestedFriend = null;
      friendLoading = false;
    });
  }

  void startGame() async {
    String collId = me.username + "GAME" + requestedFriend.username;
    Navigator.of(context).pop();
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewVersusGame(
          themes: widget.selThemes,
          images: widget.images,
          shownImages: widget.shownImages,
          mode: widget.mode,
          cards: widget.cards,
          collId: collId,
          me: widget.me,
          f: requestedFriend,
        ),
      ),
    );
  }

//Global Users tab

  Future<void> getGlobalUsers() async {
    globalUsers = new List();
    Firestore firestore = Firestore.instance;
    g1 = firestore.collection('users').snapshots().listen((sp) {
      sp.documents.forEach((d) {
        addGlobalUser(d.data);
      });
    });
    subscribeRequestStream();
  }

  void addGlobalUser(Map<String, dynamic> data) {
    String name = data['username'], profile = data['profilepic'];
    if (!(globalUsers.any(
          (f) {
            return f.username == name;
          },
        )) &&
        !(friends.any(
          (f) {
            return f.username == name;
          },
        ))) {
      if (name != null && profile != null && name != me.username) {
        ProfilePicData pf = profilePics.firstWhere((p) => p.id == profile);
        Friend f = new Friend(profile: pf, username: name);
        setState(() {
          globalUsers.add(f);
          if (globalUsers.length == 1) globalLoading = false;
        });
      }
    }
  }

  void sendRequest(Friend f) async {
    Firestore firestore = Firestore.instance;
    f.isFriend = 'requested';
    firestore.collection('friends').document().setData({
      'f1': me.username,
      'f1Prof': me.profile.id,
      'f2': f.username,
      'f2Prof': f.profile.id,
      'status': 'req',
    });
  }

  @override
  void initState() {
    super.initState();
    controller = new TabController(length: 3, vsync: this);
    getProfilePics();
    gameThemes = new List();
    generateThemes();
  }

  @override
  void dispose() {
    challengeStream.cancel();
    f1.cancel();
    f2.cancel();
    g1.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget globalLeaderBoardWidget = Container(
      child: globalLoading || requestedFriend != null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    itemCount: globalUsers.length,
                    itemBuilder: (context, i) {
                      return Container(
                        margin: EdgeInsets.all(10),
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(width: 1.0),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: CachedNetworkImage(
                                    imageUrl: globalUsers[i].profile.link,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: AutoSizeText(
                                globalUsers[i].username,
                                maxLines: 1,
                                minFontSize: 25,
                                style: TextStyle(),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: FlatButton(
                                onPressed: () {
                                  sendRequest(globalUsers[i]);
                                },
                                child: AutoSizeText(
                                  "Add Friend",
                                  minFontSize: 20,
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    ),
        friendWidget = Container(
      child: friendLoading || gameLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : friends.length == 0
              ? Center(
                  child: Text(
                    "No Friends Yet  :(",
                    style: TextStyle(
                      fontSize: 25,
                    ),
                  ),
                )
              : Column(
                  children: <Widget>[
                    Expanded(
                      child: ListView.builder(
                        itemCount: friends.length,
                        itemBuilder: (context, i) {
                          return Container(
                            margin: EdgeInsets.all(10),
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(width: 1.0),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(100),
                                      child: CachedNetworkImage(
                                        imageUrl: friends[i].profile.link,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: AutoSizeText(
                                    friends[i].username,
                                    maxLines: 1,
                                    minFontSize: 25,
                                    style: TextStyle(),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: friends[i].isFriend == "yes"
                                      ? FlatButton(
                                          onPressed: () {
                                            challengeUser(friends[i]);
                                          },
                                          child: AutoSizeText(
                                            "Challenge",
                                            minFontSize: 20,
                                            style: TextStyle(
                                              color: Colors.blueAccent,
                                            ),
                                          ),
                                        )
                                      : friends[i].isFriend == 'requested'
                                          ? AutoSizeText(
                                              "Requested",
                                              minFontSize: 20,
                                              style: TextStyle(
                                                color: Colors.red,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            )
                                          : Row(
                                              children: <Widget>[
                                                Expanded(
                                                  child: Container(
                                                    margin: EdgeInsets.only(
                                                        right: 5),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      color: Colors.redAccent,
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(
                                                        Icons.cancel,
                                                        color: Colors.white,
                                                      ),
                                                      onPressed: () {
                                                        rejectRequest(
                                                            friends[i]);
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Container(
                                                    margin: EdgeInsets.only(
                                                        right: 5),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      color: Colors.greenAccent,
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(
                                                        Icons.check,
                                                        color: Colors.white,
                                                      ),
                                                      onPressed: () {
                                                        acceptRequest(
                                                            friends[i]);
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    ),
        customGameWidget = Container(
      child: Center(
        child: Text(
          "To be Implemented",
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
    return Container(
      height: MediaQuery.of(context).size.height * 0.60,
      width: MediaQuery.of(context).size.width,
      child: DefaultTabController(
        length: 3,
        initialIndex: 0,
        child: Column(
          children: <Widget>[
            TabBar(
              onTap: (i) {
                setState(() {
                  currIndex = i;
                });
              },
              tabs: ["Friends", "Global", "Custom Game"].map<Widget>((s) {
                return Container(
                  width: MediaQuery.of(context).size.width / 4,
                  child: Tab(
                    child: Text(
                      s,
                      style: TextStyle(color: Colors.black, fontSize: 22),
                    ),
                  ),
                );
              }).toList(),
              isScrollable: true,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  friendWidget,
                  globalLeaderBoardWidget,
                  customGameWidget,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
