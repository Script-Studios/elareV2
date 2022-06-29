import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/dataClasses.dart';

class LeaderBoardTile {
  String username;
  ProfilePicData profile;
  int endlessPoints, timedPoints, randomPoints, totalPoints;
  LeaderBoardTile() {
    endlessPoints = 0;
    timedPoints = 0;
    randomPoints = 0;
    totalPoints = 0;
  }
}

class LeaderBoardDialog extends StatefulWidget {
  @override
  _LeaderBoardDialogState createState() => _LeaderBoardDialogState();
}

class _LeaderBoardDialogState extends State<LeaderBoardDialog> {
  List<LeaderBoardTile> users;
  bool loading = false;
  List<ProfilePicData> profilePics;

  void getLeaderBoard() async {
    setState(() {
      loading = true;
    });
    await getProfilePics();
    Firestore firestore = Firestore.instance;
    var qsp = await firestore.collection('users').getDocuments();
    qsp.documents.forEach((doc) {
      var d = doc.data;
      var u = new LeaderBoardTile();
      u.username = d['username'];
      u.profile = profilePics.firstWhere((p) => p.id == d['profilepic']);
      users.add(u);
    });
    var sp = await firestore.collection('games').getDocuments();

    sp.documents.forEach((doc) {
      var data = doc.data;
      String id = data['username'];
      if (id == null) id = data['userEmail'];
      if (id == null) id = "unknown";
      LeaderBoardTile user;
      if (users.isNotEmpty) {
        int k = users.indexWhere((u) => u.username == id);
        if (k != -1) user = users[k];
      }
      if (user != null) {
        if (data['mode'] == 0) {
          user.endlessPoints += int.parse(data['pointsScored'].toString());
        } else if (data['mode'] == 0) {
          user.timedPoints += int.parse(data['pointsScored'].toString());
        } else if (data['mode'] == 2) {
          user.randomPoints += int.parse(data['pointsScored'].toString());
        }
        user.username = id;
        user.totalPoints =
            user.endlessPoints + user.timedPoints + user.randomPoints;
      }
    });
    users.sort((u1, u2) {
      if (u1.totalPoints < u2.totalPoints)
        return 1;
      else if (u1.totalPoints == u2.totalPoints)
        return 0;
      else
        return -1;
    });
    setState(() {
      loading = false;
    });
  }

  Future<void> getProfilePics() async {
    profilePics = new List();
    Firestore firestore = Firestore.instance;
    var sp = await firestore.collection('profilePic').getDocuments();
    sp.documents.forEach((d) {
      profilePics.add(new ProfilePicData.fromMap(d.data));
    });
  }

  @override
  void initState() {
    super.initState();
    getLeaderBoard();
    users = new List();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xff8d9db1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      content: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Spacer(
                  flex: 3,
                ),
                Expanded(
                  flex: 10,
                  child: Text(
                    "LeaderBoard",
                    style: TextStyle(
                      fontSize: 30,
                      letterSpacing: 1,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Spacer(
                  flex: 1,
                ),
                Expanded(
                  flex: 2,
                  child: IconButton(
                    icon: Icon(
                      Icons.cancel,
                      color: Colors.orangeAccent,
                      size: 30,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
            Expanded(
              flex: 20,
              child: users.isEmpty
                  ? SizedBox(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                      height: 50,
                      width: 50,
                    )
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, i) {
                        return Container(
                          height: 60,
                          padding: EdgeInsets.all(2),
                          margin: EdgeInsets.only(bottom: 10.0),
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: i == 0 || i == 1 || i == 2 ? 5 : 0.1,
                              color: i == 0
                                  ? Color(0xffffd700)
                                  : i == 1
                                      ? Color(0xffc0c0c0)
                                      : i == 2
                                          ? Color(0xffcd7f32)
                                          : Colors.black,
                            ),
                            borderRadius: BorderRadius.circular(5),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                flex: 2,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: CachedNetworkImage(
                                      imageUrl: users[i].profile.link,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Container(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      AutoSizeText(
                                        users[i].username,
                                        maxLines: 1,
                                        style: TextStyle(),
                                      ),
                                      AutoSizeText(
                                        "Total: " +
                                            users[i].totalPoints.toString(),
                                        maxLines: 1,
                                        minFontSize: 20,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          padding: EdgeInsets.all(2),
                                          child: Image.asset(
                                            "assets/endless.jpg",
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: AutoSizeText(
                                          users[i].endlessPoints.toString(),
                                          maxLines: 1,
                                          minFontSize: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          padding: EdgeInsets.all(2),
                                          child: Image.asset(
                                            "assets/timed.png",
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: AutoSizeText(
                                          users[i].timedPoints.toString(),
                                          maxLines: 1,
                                          minFontSize: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          padding: EdgeInsets.all(2),
                                          child: Image.asset(
                                            "assets/random.png",
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: AutoSizeText(
                                          users[i].randomPoints.toString(),
                                          maxLines: 1,
                                          minFontSize: 20,
                                        ),
                                      ),
                                    ],
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
    );
  }
}
