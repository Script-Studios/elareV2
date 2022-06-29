import 'dart:async';
import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/home.dart';
import 'package:flutter_story_app_concept/main.dart';
import 'package:flutter_story_app_concept/tutorial.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreenPage extends StatefulWidget {
  @override
  _SplashScreenPageState createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage>
    with WidgetsBindingObserver {
  Timer t1, t2, logo;
  Timer checkNetwork;
  int dots = 0;
  bool onBoardingDone, loggedIn;
  bool downloading = true, connected;
  Map<String, String> rem = new Map();
  Connectivity connectivity;
  bool ssOver = false;
  bool logoChange = false;

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
    onBoardingDone = true; //remove this line when you want to keep onboarding
  }

  void checkLoggedIn() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    loggedIn = preferences.getBool("loggedIn");
    if (loggedIn == null) loggedIn = false;
  }

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

  void logoTimer() {
    logo = new Timer(Duration(milliseconds: 2500), () {
      if (this.mounted && connected != null && connected)
        setState(() {
          logoChange = !logoChange;
        });
    });
  }

  void afterTimer() {
    if (connected) {
      if (!onBoardingDone || !loggedIn) {
        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return TutorialPage(firstInstall: true);
            },
          ),
        );
      } else {
        stopAudio();
        flameAudio.clear("ss_audio.mp3");
        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return HomePage();
            },
          ),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print(state);
    if (state == AppLifecycleState.inactive) {
      if (this.mounted) ap.setVolume(0);
    } else if (state == AppLifecycleState.resumed) {
      if (this.mounted) ap.setVolume(1);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (checkNetwork != null) checkNetwork.cancel();
    if (logo != null && logo.isActive) logo.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadAudioPlayers();
    checkOnboarding();
    checkLoggedIn();
    connectivity = new Connectivity();
    //firstInstall();
    connectivity.onConnectivityChanged.listen((res) async {
      if (await checkConnectivity()) {
        connected = true;
        if (t2 != null && !t2.isActive) {
          setState(() {
            logoChange = !logoChange;
          });
          await Future.delayed(Duration(milliseconds: 1500));
          afterTimer();
        }
      } else {
        connected = false;
      }
      if (this.mounted) setState(() {});
    });
    logoTimer();
    t2 = new Timer(const Duration(milliseconds: 6000), afterTimer);
  }

  @override
  Widget build(BuildContext context) {
    String d = "";
    for (int i = 0; i < dots; i++) {
      d += ".";
    }
    int index;
    if (ssOver) {
      if (onBoardingDone) {
        if (!loggedIn) {
          index = 1;
        }
      } else {
        index = 1;
      }
    } else {
      index = 0;
    }
    var stack = IndexedStack(index: index, children: <Widget>[
      Scaffold(
        backgroundColor: Color(0xff0b0f1b),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            connected != null && !connected ? Spacer() : SizedBox(),
            Expanded(
              flex: 3,
              child: Center(
                child: AnimatedCrossFade(
                  firstChild: Center(
                    child: Hero(
                      tag: 'elare',
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
                  ),
                  secondChild: Container(
                    height: MediaQuery.of(context).size.height,
                    child: Image.asset("assets/ss.gif"),
                    color: Color(0xff0b0f1b),
                  ),
                  crossFadeState: logoChange
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  secondCurve: Curves.easeInOutExpo,
                  firstCurve: Curves.easeInOutExpo,
                  duration: Duration(
                    milliseconds: 1500,
                  ),
                ),
              ),
            ),
            connected != null && !connected
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
                : SizedBox(),
          ],
        ),
      ),
    ]
        //+ (ssOver && !onBoardingDone ? [OnBoardingPage()] : []) +
        //  (ssOver && onBoardingDone && !loggedIn ? [SignInPage()] : []),
        );
    return stack;
  }
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
              : */
