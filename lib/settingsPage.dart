import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/aboutUs.dart';
import 'package:flutter_story_app_concept/dataClasses.dart';
import 'package:flutter_story_app_concept/leaderBoard.dart';
import 'package:flutter_story_app_concept/main.dart';
import 'package:flutter_story_app_concept/tutorial.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class User {
  String username, email, city, state, gender;
  int age;
  ProfilePicData profile;
  DocumentReference firebaseReference;
  List<int> scores;
  User({
    this.age,
    this.city,
    this.email,
    this.gender,
    this.profile,
    this.state,
    this.username,
    this.firebaseReference,
    this.scores,
  });
}

class SettingsPage extends StatefulWidget {
  final Function closeSettings;
  final User me;
  List<ProfilePicData> profilePics;
  SettingsPage(this.closeSettings, this.me, this.profilePics);
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool musicOpen = false;
  List<String> audios = ["gameAudio1.mp3", "gameAudio2.mp3", "gameAudio3.mp3"];
  FirebaseUser user;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  void selectProfilePic() {
    scaffoldKey.currentState.showBottomSheet(
      (context) {
        return Container(
          height: 500,
          child: Padding(
            padding: EdgeInsets.all(30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    children: new List<Widget>.generate(
                      widget.profilePics.length,
                      (i) => GestureDetector(
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: CachedNetworkImage(
                              imageUrl: widget.profilePics[i].link,
                              placeholder: (context, s) => Container(
                                color: Colors.white,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            widget.me.profile = widget.profilePics[i];
                            saveProfile();
                            Navigator.of(context).pop();
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
    );
  }

  void saveProfile() {
    widget.me.firebaseReference
        .updateData({'profilepic': widget.me.profile.id});
  }

  void setMusic(bool music) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool("music", music);
  }

  void playSampleAudio() async {
    playBgm(gameAudio);
    await Future.delayed(Duration(seconds: 5));
    stopBgm();
  }

  Future<void> googleLogin() async {
    GoogleSignIn googleSignIn = new GoogleSignIn();
    FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        child: AlertDialog(
          backgroundColor: Color(0xff8d9db1),
          elevation: 30,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "Loading...Please wait...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
        onWillPop: () async {
          return false;
        },
      ),
    );
    var gUser = await googleSignIn.signIn();
    if (gUser != null) {
      var gAuth = await gUser.authentication;
      var cred = GoogleAuthProvider.getCredential(
          idToken: gAuth.idToken, accessToken: gAuth.accessToken);
      var res = await firebaseAuth.signInWithCredential(cred).catchError((e) {
        Fluttertoast.showToast(msg: "Error: ${e.code}");
      });
      user = res.user;
      await widget.me.firebaseReference.updateData({'email': user.email});
      widget.me.email = user.email;
      SharedPreferences preferences = await SharedPreferences.getInstance();
      await preferences.setString("email", user.email);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.transparent,
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: GestureDetector(
              onTap: widget.closeSettings,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.arrow_left,
                    color: Colors.white,
                    size: 40,
                  ),
                  Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 40,
                  ),
                ],
              ),
            ),
            title: Text(
              "Settings",
              style: TextStyle(
                fontSize: 40,
                color: Colors.white,
              ),
            ),
          ),
          Divider(
            thickness: 1,
            color: Colors.grey[500],
          ),
          widget.me != null
              ? Container(
                  child: Column(
                    children: <Widget>[
                      GestureDetector(
                        onTap: selectProfilePic,
                        child: Container(
                          height: 150,
                          width: 150,
                          //padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(250),
                            child: CachedNetworkImage(
                              imageUrl: widget.me.profile.link,
                              fit: BoxFit.contain,
                              placeholder: (context, s) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Text(
                        widget.me.username,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                        ),
                      )
                    ],
                  ),
                )
              : SizedBox(),
          widget.me != null
              ? Divider(
                  thickness: 0.3,
                  color: Colors.grey,
                )
              : SizedBox(),
          ListTile(
            leading: Icon(
              Icons.audiotrack,
              color: Colors.white,
              size: 20,
            ),
            title: Text(
              "Audio",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            trailing: Switch(
              value: music,
              onChanged: (val) async {
                if (!val && musicOpen) {
                  musicOpen = false;
                }
                setState(() {
                  music = val;
                });
                setMusic(music);
              },
              activeColor: Colors.indigoAccent,
              activeTrackColor: Color(0xff8d9db1),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.blueGrey,
            ),
            onTap: () {
              if (music) {
                setState(() {
                  musicOpen = !musicOpen;
                });
              }
            },
            subtitle: musicOpen
                ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: audios.length,
                    itemBuilder: (context, i) {
                      return ListTile(
                        title: Text(
                          "Audio ${i + 1}",
                          style: TextStyle(
                            fontSize: 20,
                            color: gameAudio == audios[i]
                                ? Colors.green
                                : Colors.white,
                            fontWeight: gameAudio == audios[i]
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          gameAudio = audios[i];
                          playSampleAudio();
                          setState(() {});
                        },
                      );
                    },
                  )
                : null,
          ),
          widget.me.email == null
              ? Divider(
                  thickness: 0.3,
                  color: Colors.grey,
                )
              : SizedBox(),
          widget.me.email == null
              ? ListTile(
                  leading: Icon(
                    Icons.sync,
                    color: Colors.white,
                    size: 20,
                  ),
                  title: Text(
                    "Save Your Progress",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  onTap: () async {
                    await googleLogin();
                    widget.closeSettings();
                  },
                )
              : SizedBox(),
          Divider(
            thickness: 0.3,
            color: Colors.grey,
          ),
          ListTile(
            leading: Icon(
              Icons.assessment,
              color: Colors.white,
              size: 20,
            ),
            title: Text(
              "Game  Statistics",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            onTap: () {
              widget.closeSettings();
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => LeaderBoardDialog(),
              );
            },
          ),
          Divider(
            thickness: 0.3,
            color: Colors.grey,
          ),
          ListTile(
            leading: Icon(
              Icons.lock_outline,
              color: Colors.white,
              size: 20,
            ),
            title: Text(
              "Privacy  Policy",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            onTap: () {
              widget.closeSettings();
              launch("https://drive.google.com/open?id=1hmifl9fMLQkyFriWVuYLKrh6ko4Qv3_Sd9qP9q6WgC8")
                  .catchError((e) {
                print(e);
              });
            },
          ),
          Divider(
            thickness: 0.3,
            color: Colors.grey,
          ),
          ListTile(
            leading: Icon(
              Icons.play_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            title: Text(
              "How  to  Play",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            onTap: () {
              widget.closeSettings();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TutorialPage(firstInstall: false),
                ),
              );
            },
          ),
          Divider(
            thickness: 0.3,
            color: Colors.grey,
          ),
          ListTile(
            leading: Icon(
              IconData(59375, fontFamily: 'MaterialIcons'),
              color: Colors.white,
              size: 20,
            ),
            title: Text(
              "About  Us",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            onTap: () {
              widget.closeSettings();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AboutUsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
