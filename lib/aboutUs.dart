import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AboutUsPage extends StatefulWidget {
  @override
  _AboutUsPageState createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  List<Member> members;
  List<bool> expanded;

  void getMembers() {
    members.add(
      new Member(
        desc:
            "He lets his code do the talk. He might come across as a very shy reserved person, but our team knows that he can really set fire in the water. He likes to live in the fable stories, waiting for his Cindrella. If it's gonna happen, it will happen.",
        name: "Harsh Lukka",
        url:
            "https://firebasestorage.googleapis.com/v0/b/elare-bd2f2.appspot.com/o/users%2Fharsh.jpg?alt=media&token=4be71455-361c-470f-b141-701166f11c05",
      ),
    );
    members.add(
      new Member(
        desc:
            "Indian Times says \"Amazing Girl\" and \"A Lady of A Kind\". I am the stylist of this app. I personally take care of the diet, the logos, the designs and the physique. And as they, you can't remove the art from the artist, I have graphics in breakfast.",
        name: "Aastha Jain",
        url:
            "https://firebasestorage.googleapis.com/v0/b/elare-bd2f2.appspot.com/o/users%2Fastha.jpeg?alt=media&token=c5de904f-a4c2-42d7-b664-90c9daf74862",
      ),
    );
    members.add(
      new Member(
        desc:
            "She knows what you want. She has been sacrificing her sleep and her exercise time to handpick photos for your pleasure. She likes to draw random stuff and bring stuff from the internet which you would like to see. A Power Ranger !",
        name: "Jahnavi Gupta",
        url:
            "https://firebasestorage.googleapis.com/v0/b/elare-bd2f2.appspot.com/o/users%2Fjahnavi.jpeg?alt=media&token=c10270ff-2db5-4c39-9d72-bf8c91483901",
      ),
    );
    members.add(
      new Member(
        desc:
            "They say the priest is more important than the couple in a marriage. I know how to pretend to chant some marketing hymns and get the word out. And yeah, I make sure you know about us. There's always a beauty with brains in a team. And that isn't me !",
        name: "Juhi Shukla",
        url:
            "https://firebasestorage.googleapis.com/v0/b/elare-bd2f2.appspot.com/o/users%2Fjuhi.jpeg?alt=media&token=101f2584-5238-446d-abe4-2975d7753a6e",
      ),
    );
    members.add(
      new Member(
        desc:
            "All I have been doing since birth is jaywalking through the streets of life. Well, my contribution in this team includes bringing coffees, answering their better half's calls and texts and babysitting. I think I inspire them too.",
        name: "Jay Dev",
        url:
            "https://firebasestorage.googleapis.com/v0/b/elare-bd2f2.appspot.com/o/users%2Fjay.jfif?alt=media&token=a4a47cca-3c12-43f9-981b-5e65b4b94159",
      ),
    );
    expanded = [
      false,
      false,
      false,
      false,
      false,
    ];
    members = members.reversed.toList();
  }

  @override
  void initState() {
    super.initState();
    members = new List();
    expanded = new List();
    getMembers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff081c36),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Spacer(),
          Expanded(
            child: Center(
              child: AutoSizeText(
                "Team Members",
                minFontSize: 30,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 10,
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, i) {
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  //height: MediaQuery.of(context).size.height * 0.4,
                  decoration: BoxDecoration(
                    color: Color(0xFF1b1e44 + 0xFF2d3447),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: MediaQuery.of(context).size.height * 0.25,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: CachedNetworkImage(
                            imageUrl: members[i].url,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Spacer(
                            flex: 2,
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              members[i].name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Spacer(),
                          Expanded(
                            child: IconButton(
                              icon: Icon(
                                expanded[i]
                                    ? Icons.arrow_drop_down
                                    : Icons.arrow_right,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () {
                                setState(() {
                                  expanded[i] = !expanded[i];
                                });
                              },
                            ),
                          )
                        ],
                      ),
                      expanded[i]
                          ? Align(
                              alignment: Alignment.topLeft,
                              child: AutoSizeText(
                                members[i].desc,
                                minFontSize: 20,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  color: Colors.grey[300],
                                ),
                              ),
                            )
                          : SizedBox(),
                    ],
                  ),
                );
              },
            ),
          ),
          Spacer(
            flex: 1,
          ),
        ],
      ),
    );
  }
}

class Member {
  String url;
  String name, desc;
  Member({@required this.name, @required this.url, @required this.desc});
}
