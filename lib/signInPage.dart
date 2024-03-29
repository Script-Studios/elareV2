import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_story_app_concept/home.dart';
import 'package:flutter_story_app_concept/main.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_story_app_concept/dataClasses.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with WidgetsBindingObserver {
  List<Widget> children;
  int age;
  String name, city, gender;
  List<String> citiesInState;
  List<StateData> states;
  StateData state;
  List<ProfilePicData> profilePics;
  ProfilePicData profilePic;
  PageController controller;
  TextEditingController nameCont, ageCont;
  List<Widget> children1;
  Connectivity connectivity;
  bool noWifiDialogOpen = false;
  bool stateLoading = false, cityLoading = false;
  List<Color> bgColor;
  List<Widget> images;
  List<String> text, hint;
  List<TextInputType> keyBoard;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseUser user;
  bool firstBuild = true;
  FocusNode nameFocus, ageFocus;
  bool usernameValid = false;

  Future<bool> checkPreviousLogin() async {
    Firestore firestore = Firestore.instance;
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var sp = await firestore
        .collection('users')
        .where('email', isEqualTo: user.email)
        .getDocuments()
        .catchError((e) {
      Fluttertoast.showToast(msg: "Error: ${e.code}");
    });
    if (sp.documents.length > 0) {
      var d = sp.documents.first.data;
      await preferences.setBool("loggedIn", true);
      await preferences.setString("username", d['username'].toString());
      await preferences.setString("email", user.email);
      await preferences.setInt('age', int.parse(d['age'].toString()));
      await preferences.setString('city', d['city'].toString());
      await preferences.setString('state', d['state'].toString());
      await preferences.setString('gender', d['gender'].toString());
      await preferences.setString('profilepic', d['profilepic'].toString());
      for (int i = 0; i < 3; i++) {
        String key = "mode${i}Score";
        int n;
        if (d[key] == null) {
          n = 0;
        } else {
          n = int.parse(d[key].toString());
        }
        await preferences.setInt(key, n);
      }
      Fluttertoast.showToast(
          msg: "Good to see you back, ${d['username'].toString()}  :)");
      return true;
    } else {
      return false;
    }
  }

  void googleLogin() async {
    GoogleSignIn googleSignIn = new GoogleSignIn();
    FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    await Future.delayed(Duration(seconds: 1));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        child: AlertDialog(
          backgroundColor: bgColor[0].withRed(200),
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
    await googleSignIn.signOut();
    var gUser = await googleSignIn.signIn();
    while (gUser == null) {
      await Fluttertoast.showToast(
        msg: "Please Sign in with Google....",
        toastLength: Toast.LENGTH_SHORT,
      );
      gUser = await googleSignIn.signIn();
    }
    var gAuth = await gUser.authentication;
    var cred = GoogleAuthProvider.getCredential(
        idToken: gAuth.idToken, accessToken: gAuth.accessToken);
    var res = await firebaseAuth.signInWithCredential(cred).catchError((e) {
      Fluttertoast.showToast(msg: "Error: ${e.code}");
    });
    user = res.user;
    if (await checkPreviousLogin()) {
      stopBgm();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pushNamed("home");
    } else {
      Navigator.of(context).pop();
    }
  }

  void getProfilePics() async {
    profilePics = new List();
    Firestore firestore = Firestore.instance;
    var sp = await firestore.collection('profilePic').getDocuments();
    sp.documents.forEach((d) {
      profilePics.add(new ProfilePicData.fromMap(d.data));
    });
    setState(() {});
  }

  void flutterToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void addPage() {
    if (children.length < 3 && controller.page.toInt() == children.length - 1)
      setState(() {
        children.add(children1[children.length]);
      });
  }

  void onPressedNext() {
    controller.nextPage(
      duration: Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  void onPressedBack() {
    controller.previousPage(
      duration: Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  void onChanged() {
    setState(() {});
  }

  void onSubmit() async {
    if (profilePic != null) {
      stopBgm();
      Firestore firestore = Firestore.instance;
      SharedPreferences preferences = await SharedPreferences.getInstance();
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
              child: AlertDialog(
                backgroundColor: bgColor[0].withRed(200),
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
              }));
      String email = user != null ? user.email : null;
      await preferences.setBool("loggedIn", true);
      await preferences.setString("username", name);
      await preferences.setString("email", email);
      await preferences.setInt('age', age);
      await preferences.setString('city', city);
      await preferences.setString('state', state.name);
      await preferences.setString('gender', gender);
      await preferences.setString('profilepic', profilePic.id);
      for (int i = 0; i < 3; i++) {
        String key = "mode${i}Score";
        await preferences.setInt(key, 0);
      }
      var sp = await firestore
          .collection('users')
          .where('username', isEqualTo: name)
          .getDocuments();
      if (sp.documents.isEmpty) {
        await firestore.collection('users').document().setData({
          'username': name,
          'email': user != null ? user.email : null,
          'age': age,
          'city': city,
          'state': state.name,
          'gender': gender,
          'profilepic': profilePic.id,
        }).catchError((e) {
          print(e);
        });
      }
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => HomePage(), //SelectInterests(),
        ),
      );
    } else {
      flutterToast("Please select your emoticon..");
    }
  }

  void startMusic() {
    playBgm("onboard.mp3");
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

  void getCities() {
    setState(() {
      cityLoading = true;
    });
    citiesInState = state.cities;
    citiesInState.sort();
    setState(() {
      cityLoading = false;
    });
  }

  void getStates() async {
    setState(() {
      stateLoading = true;
    });
    states = new List();
    Firestore firestore = Firestore.instance;
    var sp = await firestore.collection('cities').getDocuments();
    if (sp.documents.length == 1) {
      var d = sp.documents.first.data;
      d.forEach((st, cities) {
        states.add(
          new StateData(
            st,
            new List<String>.generate(
              cities.length,
              (i) => cities[i].toString(),
            ),
          ),
        );
      });
      states.sort((s1, s2) {
        return s1.name.compareTo(s2.name);
      });
      setState(() {
        stateLoading = false;
      });
    }
  }

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
                      profilePics.length,
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
                              imageUrl: profilePics[i].link,
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
                            profilePic = profilePics[i];
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

  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      if (this.mounted) bgm.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (this.mounted) bgm.resume();
    }
  }

  void signInDialog() async {
    await Future.delayed(Duration(seconds: 1));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        child: AlertDialog(
          //backgroundColor: bgColor[0].withRed(200),
          elevation: 30,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "Sign In With Google",
                style: TextStyle(
                  //color: Colors.white,
                  fontSize: 25,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            RaisedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Skip",
                style: TextStyle(
                  fontSize: 25,
                ),
              ),
              color: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            RaisedButton(
              onPressed: () {
                Navigator.of(context).pop();
                googleLogin();
              },
              child: Text(
                "Continue",
                style: TextStyle(
                  fontSize: 25,
                ),
              ),
              color: Color(0xFF126C20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ],
        ),
        onWillPop: () async {
          return false;
        },
      ),
    );
  }

  Future<void> checkUsernameExists() async {
    Firestore firestore = Firestore.instance;
    var sp = await firestore
        .collection('users')
        .where('username', isEqualTo: name)
        .getDocuments();
    if (sp.documents.length == 0) {
      usernameValid = true;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    startMusic();
    getProfilePics();
    connectivity = new Connectivity();
    connectivity.onConnectivityChanged.listen((res) async {
      if (await checkConnectivity()) {
        removeDialog();
      } else {
        notConnectedDialog();
      }
    });
    controller = new PageController(
      keepPage: true,
    );
    nameCont = new TextEditingController();
    ageCont = new TextEditingController();
    getStates();
    citiesInState = [];
    bgColor = [
      Color(0xFF126C20),
      Color(0xFFF2BB25),
      Color(0xFF8ED547 + 0xFFF2BB25),
      Color(0xFF8ED547),
      Color(0xFF126C20 + 0xFFF2BB25)
    ];
    images = [
      CachedNetworkImage(
        imageUrl:
            "https://firebasestorage.googleapis.com/v0/b/elare-bd2f2.appspot.com/o/assets%2Fsecond.png?alt=media&token=32ae79e7-34d4-4667-b323-f396a7c26f6b",
        placeholder: (context, s) {
          return Container(
            child: Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.white,
              ),
            ),
            color: bgColor[0],
          );
        },
        errorWidget: (context, s, o) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.error_outline,
                  color: bgColor[0],
                ),
                Text(
                  "Error loading",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      CachedNetworkImage(
        imageUrl:
            "https://firebasestorage.googleapis.com/v0/b/elare-bd2f2.appspot.com/o/assets%2Ffirst.png?alt=media&token=2524e1b6-1823-4638-bdd9-e34f3c06681d",
        placeholder: (context, s) {
          return Container(
            child: Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.white,
              ),
            ),
            color: bgColor[1],
          );
        },
        errorWidget: (context, s, o) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.error_outline,
                  color: bgColor[1],
                ),
                Text(
                  "Error loading",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      null,
      CachedNetworkImage(
        imageUrl:
            "https://firebasestorage.googleapis.com/v0/b/elare-bd2f2.appspot.com/o/assets%2Fthird.png?alt=media&token=b77e8171-6004-43af-bdb5-41ffc5509f92",
        placeholder: (context, s) {
          return Container(
            child: Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.white,
              ),
            ),
            color: bgColor[3],
          );
        },
        errorWidget: (context, s, o) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.error_outline,
                  color: bgColor[3],
                ),
                Text(
                  "Error loading",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      null,
    ];
    text = [
      'What do you want us to call you by',
      'How old are you',
      'Select Your Gender',
      'Where are you from',
      'Select your Emoticon',
    ];
    hint = ['Name', 'Age', null, 'State', null];
    keyBoard = [TextInputType.text, TextInputType.number, null, null, null];
    nameFocus = new FocusNode();
    ageFocus = new FocusNode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (firstBuild) {
      signInDialog();
      //googleLogin();
      firstBuild = false;
    }
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: PageView.builder(
        itemCount: 5,
        onPageChanged: (i) {
          if (nameFocus.hasFocus) nameFocus.unfocus();
          if (ageFocus.hasFocus) ageFocus.unfocus();
          if (i == 0) {
          } else if (i == 1) {
            if (nameCont.value.text.length == 0) {
              controller.previousPage(
                duration: Duration(milliseconds: 500),
                curve: Curves.ease,
              );
              flutterToast("Please add Name..");
            } else if (!usernameValid) {
              controller.previousPage(
                duration: Duration(milliseconds: 500),
                curve: Curves.ease,
              );
              flutterToast("Username already exists");
            } else {
              if (ageCont.value.text.length == 0) {
                FocusScope.of(context).requestFocus(ageFocus);
              }
            }
          } else if (i == 2) {
            if (ageCont.value.text.length == 0) {
              controller.previousPage(
                duration: Duration(milliseconds: 500),
                curve: Curves.ease,
              );
              flutterToast("Please add Age..");
            }
          } else if (i == 3) {
            if (gender == null) {
              controller.previousPage(
                duration: Duration(milliseconds: 500),
                curve: Curves.ease,
              );
              flutterToast("Please select Gender..");
            }
          } else if (i == 4) {
            if (city == null) {
              controller.previousPage(
                duration: Duration(milliseconds: 500),
                curve: Curves.ease,
              );
              flutterToast("Please select City..");
            }
          }
        },
        controller: controller,
        itemBuilder: (context, i) {
          return Scaffold(
            key: i == 4 ? scaffoldKey : null,
            body: Container(
              padding: EdgeInsets.all(30),
              color: bgColor[i],
              child: Column(
                children: <Widget>[
                  Spacer(
                    flex: 1,
                  ),
                  Expanded(
                    flex: 4,
                    child: i == 2
                        ? Row(
                            children: <Widget>[
                              Expanded(
                                flex: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      gender = "male";
                                    });
                                  },
                                  child: Column(
                                    children: <Widget>[
                                      SizedBox(
                                        height: 30,
                                      ),
                                      Container(
                                        height: 120,
                                        width: 120,
                                        foregroundDecoration: BoxDecoration(
                                          color: gender == "male"
                                              ? Colors.yellowAccent
                                                  .withOpacity(0.3)
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.transparent,
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(150),
                                          child: Opacity(
                                            opacity:
                                                gender == "male" ? 0.25 : 1,
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  "https://firebasestorage.googleapis.com/v0/b/elare-bd2f2.appspot.com/o/assets%2Fmale_emoji.png?alt=media&token=cd5999b4-a61e-4a6f-817e-69fadffd7161",
                                              placeholder: (context, s) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            500),
                                                    color: bgColor[2],
                                                  ),
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      backgroundColor:
                                                          Colors.white,
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorWidget: (context, s, o) {
                                                return Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      Icon(
                                                        Icons.error_outline,
                                                        color: bgColor[0],
                                                      ),
                                                      Text(
                                                        "Error loading",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "Male",
                                        style: TextStyle(
                                          color: gender == "male"
                                              ? Colors.yellow
                                              : Colors.white,
                                          fontSize: 25,
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
                                flex: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      gender = "female";
                                    });
                                  },
                                  child: Column(
                                    children: <Widget>[
                                      SizedBox(
                                        height: 30,
                                      ),
                                      Container(
                                        height: 120,
                                        width: 120,
                                        foregroundDecoration: BoxDecoration(
                                          color: gender == "female"
                                              ? Colors.pinkAccent
                                                  .withOpacity(0.3)
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.transparent,
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(150),
                                          child: Opacity(
                                            opacity:
                                                gender == "female" ? 0.25 : 1,
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  "https://firebasestorage.googleapis.com/v0/b/elare-bd2f2.appspot.com/o/assets%2Ffemale_emoji.png?alt=media&token=75f2829d-dbdf-4580-97fd-9295cb9912d5",
                                              placeholder: (context, s) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            250),
                                                    color: bgColor[2],
                                                  ),
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      backgroundColor:
                                                          Colors.white,
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorWidget: (context, s, o) {
                                                return Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      Icon(
                                                        Icons.error_outline,
                                                        color: bgColor[0],
                                                      ),
                                                      Text(
                                                        "Error loading",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "Female",
                                        style: TextStyle(
                                          color: gender == "female"
                                              ? Colors.pink
                                              : Colors.white,
                                          fontSize: 25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : i == 4
                            ? GestureDetector(
                                onTap: selectProfilePic,
                                child: Container(
                                  padding: EdgeInsets.all(20),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(250.0),
                                    child: profilePic != null
                                        ? CachedNetworkImage(
                                            imageUrl: profilePic.link)
                                        : CachedNetworkImage(
                                            imageUrl:
                                                "https://firebasestorage.googleapis.com/v0/b/elare-bd2f2.appspot.com/o/assets%2FuserAccount.jpg?alt=media&token=c46c0c83-c12e-48de-9f46-56e002487c73",
                                            placeholder: (context, s) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          250),
                                                  color: bgColor[4],
                                                ),
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    backgroundColor:
                                                        Colors.white,
                                                  ),
                                                ),
                                              );
                                            },
                                            errorWidget: (context, s, o) {
                                              return Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    Icon(
                                                      Icons.error_outline,
                                                      color: bgColor[1],
                                                    ),
                                                    Text(
                                                      "Error loading",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    //borderRadius: BorderRadius.circular(300.0),
                                  ),
                                ),
                              )
                            : images[i],
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Spacer(),
                        Expanded(
                          flex: 3,
                          child: AutoSizeText(
                            text[i],
                            overflow: TextOverflow.visible,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            minFontSize: 35,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: new List<Widget>.generate(
                              5,
                              (j) {
                                return Container(
                                  width: i == j ? 30 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                      color: i == 0
                                          ? Colors.white
                                          : Colors.white70,
                                      borderRadius: BorderRadius.circular(10)),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        i == 2
                            ? Spacer()
                            : Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  child: i == 3
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: <Widget>[
                                            Expanded(
                                              flex: 1,
                                              child: stateLoading
                                                  ? Center(
                                                      child: SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                    )
                                                  : DropdownButton<StateData>(
                                                      hint: Text("State"),
                                                      isExpanded: true,
                                                      value: state,
                                                      items: new List<
                                                          DropdownMenuItem<
                                                              StateData>>.generate(
                                                        states.length,
                                                        (i) {
                                                          return DropdownMenuItem<
                                                                  StateData>(
                                                              child:
                                                                  AutoSizeText(
                                                                      states[i]
                                                                          .name),
                                                              value: states[i]);
                                                        },
                                                      ),
                                                      onChanged: (st) {
                                                        state = st;
                                                        city = null;
                                                        getCities();
                                                        setState(() {});
                                                      },
                                                    ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: cityLoading
                                                  ? Center(
                                                      child: SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                    )
                                                  : DropdownButton(
                                                      hint: Text("City"),
                                                      isExpanded: true,
                                                      value: city,
                                                      items: new List<
                                                          DropdownMenuItem<
                                                              String>>.generate(
                                                        citiesInState.length +
                                                            1,
                                                        (i) {
                                                          if (i ==
                                                              citiesInState
                                                                  .length) {
                                                            return DropdownMenuItem<
                                                                String>(
                                                              child:
                                                                  AutoSizeText(
                                                                "Other",
                                                              ),
                                                              value: "Other",
                                                            );
                                                          } else
                                                            return DropdownMenuItem<
                                                                String>(
                                                              child: AutoSizeText(
                                                                  citiesInState[
                                                                      i]),
                                                              value:
                                                                  citiesInState[
                                                                      i],
                                                            );
                                                        },
                                                      ),
                                                      onChanged: (String s) {
                                                        city = s;
                                                        setState(() {});
                                                      },
                                                    ),
                                            ),
                                          ],
                                        )
                                      : i == 4
                                          ? GestureDetector(
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 5),
                                                child: Center(
                                                  child: Text(
                                                    "Change your Avatar",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 20.0,
                                                    ),
                                                  ),
                                                ),
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width -
                                                    150,
                                              ),
                                              onTap: selectProfilePic,
                                            )
                                          : TextField(
                                              focusNode: i == 0
                                                  ? nameFocus
                                                  : i == 1 ? ageFocus : null,
                                              keyboardType: keyBoard[i],
                                              controller: i == 0
                                                  ? nameCont
                                                  : i == 1 ? ageCont : null,
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 25.0,
                                              ),
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                hintText: hint[i],
                                                hintStyle: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 25,
                                                ),
                                              ),
                                              onEditingComplete: () async {
                                                if (i == 0) {
                                                  await checkUsernameExists();
                                                  if (usernameValid)
                                                    onPressedNext();
                                                  else
                                                    flutterToast(
                                                        "Username already exists!!");
                                                } else if (i == 1) {
                                                  onPressedNext();
                                                }
                                              },
                                              onChanged: (s) {
                                                if (i == 1) {
                                                  age = int.parse(s);
                                                  print(age);
                                                } else {
                                                  usernameValid = false;
                                                  name = s;
                                                }
                                                setState(() {});
                                              },
                                            ),
                                ),
                              ),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              i > 0
                                  ? FlatButton(
                                      onPressed: onPressedBack,
                                      child: Text(
                                        'Back',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    )
                                  : SizedBox(),
                              i < 4
                                  ? FlatButton(
                                      onPressed: onPressedNext,
                                      child: Text(
                                        'Next',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    )
                                  : FlatButton(
                                      onPressed: onSubmit,
                                      child: Text(
                                        'Submit',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
