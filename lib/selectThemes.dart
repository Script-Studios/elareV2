import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/dataClasses.dart';
import 'package:flutter_story_app_concept/main.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SelectThemes extends StatefulWidget {
  List<GameTheme> themes, selThemes;
  final Function selected;
  SelectThemes(this.themes, this.selThemes, this.selected);
  @override
  _SelectThemesState createState() => _SelectThemesState(themes, selThemes);
}

class _SelectThemesState extends State<SelectThemes> {
  List<GameTheme> themes, selThemes;
  List<String> imageLoc = [
    "assets/endless.jpg",
    "assets/timed.png",
    "assets/random.png",
  ];
  _SelectThemesState(this.themes, this.selThemes);
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        backgroundColor: Color(0xff081c36),
        floatingActionButton: selThemes.length > 0
            ? RaisedButton(
                padding: EdgeInsets.all(15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.green[700],
                onPressed: () {
                  widget.selected();
                  Navigator.of(context).pop();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Done",
                      style: TextStyle(
                        fontSize: 25,
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Icon(Icons.check)
                  ],
                ),
              )
            : null,
        body: Column(
          children: <Widget>[
            Spacer(
              flex: 1,
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.center,
                child: AutoSizeText(
                  "Select Themes:",
                  style: TextStyle(
                    color: Color(0xff8d9db1),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                  minFontSize: 30,
                ),
              ),
            ),
            Expanded(
              flex: 8,
              child: ListView.builder(
                itemCount: themes.length,
                itemBuilder: (context, i) {
                  var t = themes[i];
                  bool selected = selThemes.any((th) {
                    return th.id == t.id;
                  });
                  bool locked = false;
                  for (int i = 0; i < 3; i++) {
                    if (me.scores[i] < t.minScore[i]) locked = true;
                  }
                  Stack st = new Stack(
                    children: <Widget>[
                      GestureDetector(
                        onTap: locked
                            ? null
                            : () {
                                if (selected) {
                                  selThemes.remove(t);
                                } else {
                                  selThemes.add(t);
                                }
                                setState(() {});
                              },
                        child: Opacity(
                          opacity: locked ? 0.2 : 0.95,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25.0),
                              color:
                                  selected ? Colors.green : Color(0xff8d9db1),
                            ),
                            margin: EdgeInsets.symmetric(vertical: 15),
                            padding: EdgeInsets.only(top: 10),
                            child: Column(
                              children: <Widget>[
                                Container(
                                  width: MediaQuery.of(context).size.width - 10,
                                  height: 150,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: t.loc != null
                                        ? Image.file(
                                            File(t.loc),
                                            fit: BoxFit.fitWidth,
                                          )
                                        : CachedNetworkImage(
                                            imageUrl: t.coverUrl,
                                            fit: BoxFit.fitWidth,
                                          ),
                                  ),
                                ),
                                SizedBox(
                                  height: 8,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(Icons.arrow_back),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    AutoSizeText(
                                      t.type0,
                                      minFontSize: 22,
                                    ),
                                    SizedBox(
                                      width: 25,
                                    ),
                                    AutoSizeText(
                                      t.type1,
                                      minFontSize: 22,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Icon(Icons.arrow_forward),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                  if (locked) {
                    st.children.add(
                      Positioned(
                        width: MediaQuery.of(context).size.width,
                        height: 180,
                        top: 25,
                        child: Container(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Icon(
                                Icons.lock_outline,
                                color: Colors.white,
                                size: 25,
                              ),
                              Text(
                                "Target:",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: new List<Widget>.generate(3, (i) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Container(
                                        height: 50,
                                        width: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(
                                            color: Colors.white,
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
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        me.scores[i].toString() +
                                            " / " +
                                            t.minScore[i].toString(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return st;
                },
              ),
            )
          ],
        ),
      ),
      onWillPop: () async {
        if (selThemes.length == 0) {
          Fluttertoast.showToast(msg: "Please select a theme");
          return false;
        } else {
          widget.selected();
          return true;
        }
      },
    );
  }
}
