import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

List<String> names1 = new List.generate(101, (i) {
  String s = "/boys_girls/boys/";
  int z = 3 - (i + 1).toString().length;
  while (z > 0) {
    s += "0";
    z--;
  }

  if (i == 91)
    s += (i + 1).toString() + ".jpeg";
  else
    s += (i + 1).toString() + ".jpg";
  return s;
}),
    names2 = new List.generate(101, (i) {
  String s = "/boys_girls/girls/";
  int z = 3 - (i + 1).toString().length;
  while (z > 0) {
    s += "0";
    z--;
  }
  s += (i + 1).toString() + ".jpg";
  return s;
});

class Dummy extends StatelessWidget {
  const Dummy({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: RaisedButton(
          /* onPressed: () async {
            Firestore firestore = Firestore.instance;
            var sp = await firestore.collection('themes').getDocuments();
            sp.documents.forEach((doc) async {
              var data = doc.data;
              List<dynamic> im = data['images'];
              im.forEach((i) {
                i.remove('ratio');
                i.addAll({
                  'correct': 0,
                  'total': 0,
                });
              });
              await doc.reference.updateData({
                'images': data['images'],
              });
            });
          }, */
          onPressed: () async {
            FirebaseStorage fs = FirebaseStorage.instance;
            Firestore firestore = Firestore.instance;
            List<Map<String, dynamic>> images = new List();
            print(names1);
            /* FirebaseAuth auth = FirebaseAuth.instance;
            auth.createUserWithEmailAndPassword(
                email: "hplukka@gmail.com", password: "harsh@210599");
             */
            for (var n in names1) {
              print(n);
              var url = await fs.ref().child(n).getDownloadURL();
              images.add({
                'link': url,
                'correct': 0,
                'total': 0,
                'type': 0,
              });
            }
            for (var n in names2) {
              print(n);
              var url = await fs.ref().child(n).getDownloadURL();
              images.add({
                'link': url,
                'correct': 0,
                'total': 0,
                'type': 1,
              });
            }
            var qs = await firestore
                .collection('themes')
                .where('id', isEqualTo: 'BYGL')
                .getDocuments();
            var doc = qs.documents.first;
            doc.reference.updateData({'images': images});
          },
          /* onPressed: () async {
            Firestore f = Firestore.instance;
            FirebaseStorage firebaseStorage = FirebaseStorage.instance;
            List<String> n = ['home_alone.jpeg', 'spongebob.jpeg'];
            n.forEach((i) async {
              bool er = false;
              var url = await firebaseStorage
                  .ref()
                  .child("/profilePicData/$i")
                  .getDownloadURL()
                  .catchError((e) {
                print(i);
                er = true;
              });
              if (!er)
                await f.collection('profilePic').document().setData({
                  'url': url,
                  'id': i,
                });
            });
          }, */
        ),
      ),
    );
  }
}
