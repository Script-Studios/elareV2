import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Friend {
  String username;
  ProfilePicData profile;
  String isFriend;
  DocumentReference ref;
  Friend({this.profile, this.username, this.isFriend, this.ref});
}

class StateData {
  String name;
  List<String> cities;
  StateData(this.name, this.cities);
}

class ProfilePicData {
  String link, id;
  ProfilePicData.fromMap(Map<String, dynamic> data) {
    this.id = data['id'];
    this.link = data['url'];
  }
}

class GameTheme {
  String id;
  List<GameImage> images;
  int popularity, rating, timePlayed;
  String topPlayer;
  int topScore;
  String type0, type1;
  String coverUrl;
  String loc;
  List<int> minScore;
  GameTheme({
    this.id,
    this.images,
    this.popularity,
    this.rating,
    this.timePlayed,
    this.topPlayer,
    this.topScore,
    this.type0,
    this.type1,
    this.coverUrl,
    this.loc,
    this.minScore,
  });
  GameTheme.fromMap(Map<String, dynamic> data, {String location}) {
    this.images = new List.generate(
      data['images'].length,
      (i) {
        return new GameImage.fromMap(
          data['images'][i],
        );
      },
    );
    this.popularity = data['popularity'];
    this.rating = data['rating'];
    this.timePlayed = data['timePlayed'];
    this.topPlayer = data['topPlayer'];
    this.topScore = data['topScore'];
    this.type0 = data['type0'];
    this.type1 = data['type1'];
    this.id = data['id'];
    this.coverUrl = data['cover'];
    this.loc = location;
    this.minScore = [0, 0, 0];
    //this.minScore = List<int>.generate(3, (i) => data['minScore'][i]);
  }
}

class GameImage {
  String link;
  int type;
  int correct;
  int total;
  GameImage.fromMap(Map<String, dynamic> data) {
    this.link = data['link'];
    this.type = data['type'];
    this.correct = data['correct'].toInt();
    this.total = data['total'].toInt();
  }
}

class ImageShow {
  GameImage image;
  String themeId;
  String type0, type1;
  int imgIndex;
  ImageShow({
    @required this.image,
    @required this.imgIndex,
    @required this.themeId,
    @required this.type0,
    @required this.type1,
  });
}

class Swipe {
  ImageShow image;
  int swipe; //0 for left, 1 for right
  Swipe({@required this.image, @required this.swipe});
}
