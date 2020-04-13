import 'dart:async';
import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flame/flame.dart';
import 'package:flame/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/home.dart';
import 'package:flutter_story_app_concept/onboarding.dart';
import 'package:flutter_story_app_concept/signInPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class SplashScreenPage extends StatefulWidget {
  @override
  _SplashScreenPageState createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  Timer t1, t2;
  Timer dl, checkNetwork;
  int dots = 0;
  bool display = false;
  bool onBoardingDone, loggedIn;
  FlameAudio audio;
  bool downloading = true, connected;
  Map<String, String> rem = new Map();
  Connectivity connectivity;

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

  void checkOnboarding() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    onBoardingDone = preferences.getBool("onBoardingDone");
    if (onBoardingDone == null) onBoardingDone = false;
  }

  void checkLoggedIn() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    loggedIn = preferences.getBool("loggedIn");
    if (loggedIn == null) loggedIn = false;
  }

  /* void firstInstall() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    Map<String, String> audios = {
      "gameAudio.mp3":
          "https://firebasestorage.googleapis.com/v0/b/elare-bd2f2.appspot.com/o/assets%2FgameAudio.mp3?alt=media&token=607f4f12-f23b-4790-96d7-b278341a616a",
      "login.mp3":
          "https://firebasestorage.googleapis.com/v0/b/elare-bd2f2.appspot.com/o/assets%2Flogin.mp3?alt=media&token=b1912677-bfbd-4ea6-88e6-e092672cacdc",
      "gameOver.mp3":
          "https://firebasestorage.googleapis.com/v0/b/elare-bd2f2.appspot.com/o/assets%2Fgame_over.mp3?alt=media&token=7d917d66-2fb5-4038-951c-b98879f729d0",
    };

    audios.forEach((name, url) {
      String addr = preferences.getString("gameAudioAddress");
      if (addr == null) {
        rem.addAll({name: url});
      }
    });
  } */

  /* void downloadAudio() async {
    dl = new Timer.periodic(Duration(milliseconds: 300), (t) {
      dots += 1;
      dots %= 5;
      if (this.mounted) setState(() {});
    });
    setState(() {
      downloading = true;
    });
    FirebaseStorage firebaseStorage = FirebaseStorage.instance;
    final Directory appDirectory = await getApplicationDocumentsDirectory();
    final String pictureDirectory = '${appDirectory.path}/audios';
    await Directory(pictureDirectory).create(recursive: true);
    for (var name in rem.keys) {
      var url = rem[name];
      var address = '$pictureDirectory/gameAudio.mp3';
      bool err = false;
      var ref = await firebaseStorage.getReferenceFromUrl(url);
      var data = await ref.getData(2048).catchError((e) {
        print(e);
        err = true;
      });
      print("Downloaded $name");
      if (!err) {
        File f = new File(address);
        await f.writeAsBytes(data);
        SharedPreferences preferences = await SharedPreferences.getInstance();
        await preferences.setString(name, address);
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (!onBoardingDone)
            return OnBoardingPage();
          else if (!loggedIn) {
            return SignInPage();
          } else
            return Home();
        },
      ),
    );
  } */

  void checkNetworkTimer() {
    checkNetwork = Timer.periodic(Duration(seconds: 10), (t) async {
      if (await checkConnectivity()) {
        connected = true;
      } else {
        connected = false;
      }
      if (this.mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    if (dl != null) dl.cancel();
    if (checkNetwork != null) checkNetwork.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    checkOnboarding();
    checkLoggedIn();
    connectivity = new Connectivity();
    //firstInstall();
    connectivity.onConnectivityChanged.listen((res) async {
      if (await checkConnectivity()) {
        connected = true;
      } else {
        connected = false;
      }
      if (this.mounted) setState(() {});
    });
    audio = Flame.audio;
    t1 = new Timer(const Duration(milliseconds: 250), () {
      setState(() {
        display = true;
      });
      audio.clearAll();
      audio.play("ss_audio.mp3");
      t2 = new Timer(
        const Duration(milliseconds: 5000),
        () {
          audio.clearAll();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                if (!onBoardingDone)
                  return OnBoardingPage();
                else if (!loggedIn) {
                  return SignInPage();
                } else
                  return Home();
              },
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    String d = "";
    for (int i = 0; i < dots; i++) {
      d += ".";
    }
    return Scaffold(
      backgroundColor: Color(0xff0b0f1b),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Center(
              child: AnimatedCrossFade(
                firstChild: Container(),
                secondChild: Container(
                  height: MediaQuery.of(context).size.height,
                  child: Image.asset("assets/ss.gif"),
                  color: Color(0xff0b0f1b),
                ),
                crossFadeState: display
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: Duration(
                  seconds: 2,
                ),
              ),
            ),
          ),
          /* rem != null && rem.length > 0 && downloading && connected
              ? Expanded(
                  flex: 1,
                  child: Column(
                    children: <Widget>[
                      Text(
                        "Downloading" + d,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25.0,
                        ),
                      ),
                      Text(
                        "First time Loading",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                        ),
                      ),
                      Text(
                        "It might take upto a minute  :|",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                        ),
                      ),
                    ],
                  ),
                )
              : connected != null && !connected
                  ? Expanded(
                      flex: 1,
                      child: Text(
                        "No Internet Connected!",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 25.0,
                        ),
                      ),
                    )
                  : Spacer(
                      flex: 1,
                    ), */
        ],
      ),
    );
  }
}
