import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_story_app_concept/tutorial.dart';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

class InterestData {
  String link;
  String id;
  String name;
  InterestData.fromMap(Map<String, dynamic> data) {
    this.link = data['link'];
    this.id = data['id'];
    this.name = data['name'];
  }
}

class SelectInterests extends StatefulWidget {
  @override
  _SelectInterestsState createState() => _SelectInterestsState();
}

class _SelectInterestsState extends State<SelectInterests> {
  List<InterestData> interests;
  List<bool> sel;
  PageController pageController;
  double pageOffset = 0;

  void fetchInterests() async {
    interests = new List();
    sel = new List();
    Firestore firestore = Firestore.instance;
    var sp = await firestore.collection('interests').getDocuments();
    sp.documents.forEach((d) {
      interests.add(new InterestData.fromMap(d.data));
      sel.add(false);
    });
    interests.sort((i1, i2) {
      return i1.name.compareTo(i2.name);
    });
    setState(() {});
  }

  void selectInterest(int i) {
    setState(() {
      sel[i] = !sel[i];
    });
  }

  @override
  void initState() {
    super.initState();
    fetchInterests();
    pageController = PageController(viewportFraction: 0.8);
    pageController.addListener(() {
      setState(() => pageOffset = pageController.page);
    });
  }

  @override
  Widget build(BuildContext context) {
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
        floatingActionButton: sel.any((elem) {
          return elem;
        })
            ? FloatingActionButton(
                onPressed: () async {
                  Firestore firestore = Firestore.instance;
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TutorialPage(firstInstall: false),
                    ),
                  );
                  SharedPreferences preferences =
                      await SharedPreferences.getInstance();
                  var username = preferences.getString("username");
                  var sp = await firestore
                      .collection('users')
                      .where('username', isEqualTo: username)
                      .getDocuments();
                  if (sp.documents.length == 1) {
                    var doc = sp.documents.first;
                    List<String> interestsSelected = new List();
                    for (int i = 0; i < sel.length; i++) {
                      if (sel[i]) {
                        interestsSelected.add(interests[i].name);
                      }
                    }
                    await doc.reference.updateData({
                      'interests': interestsSelected,
                    });
                  }
                },
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                ),
                backgroundColor: Color(0xffff5c48),
              )
            : null,
        body: Column(
          children: <Widget>[
            Spacer(),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 12.0,
                  right: 12.0,
                  top: 40.0,
                  bottom: 8.0,
                ),
                child: AutoSizeText(
                  "Select things you feel familiar:",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  minFontSize: 24,
                  maxLines: 1,
                ),
              ),
            ),
            Expanded(
              flex: 8,
              child: interests.length > 0
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height * 0.60,
                      child: PageView.builder(
                        controller: pageController,
                        itemCount: interests.length,
                        itemBuilder: (context, i) {
                          return SlidingCard(
                            name: interests[i].name,
                            assetName: interests[i].link,
                            offset: pageOffset - i,
                            selected: sel[i],
                            index: i,
                            select: selectInterest,
                          );
                        },
                      ),
                    )
                  : SizedBox(
                      height: MediaQuery.of(context).size.height * 0.60,
                      child: Center(
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }
}

class SlidingCard extends StatelessWidget {
  final String name;
  final String assetName;
  final double offset;
  final bool selected;
  final Function select;
  final int index;

  const SlidingCard({
    Key key,
    @required this.name,
    @required this.assetName,
    @required this.offset,
    @required this.selected,
    @required this.select,
    @required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double gauss = math.exp(-(math.pow((offset.abs() - 0.5), 2) / 0.08));
    return Transform.translate(
      offset: Offset(-32 * gauss * offset.sign, 0),
      child: Card(
        margin: EdgeInsets.only(left: 8, right: 8, bottom: 24, top: 8),
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Column(
          children: <Widget>[
            SizedBox(height: 8),
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: CachedNetworkImage(
                  imageUrl: assetName,
                  placeholder: (context, s) {
                    return Container(
                      height: 230,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        color: Colors.white,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    );
                  },
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: CardContent(
                name: name,
                offset: gauss,
                selected: selected,
                select: () {
                  select(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardContent extends StatelessWidget {
  final String name;
  final double offset;
  final bool selected;
  final Function select;

  const CardContent({
    Key key,
    @required this.name,
    @required this.offset,
    @required this.selected,
    @required this.select,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Text(
              name,
              style: TextStyle(fontSize: 35),
            ),
          ),
          Spacer(
            flex: 2,
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.maxFinite,
              child: RaisedButton(
                color: selected
                    ? Color(0xFF162A49).withOpacity(0.6)
                    : Color(0xFF162A49),
                child: Transform.translate(
                  offset: Offset(24 * offset, 0),
                  child: Text(
                    'Select',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                textColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                onPressed: select,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
