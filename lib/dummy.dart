import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

List<String> names1 = new List.generate(300, (i) {
  String s = "/marvel_dc/marvel/";
  int z = 4 - (i + 1).toString().length;
  while (z > 0) {
    s += "0";
    z--;
  }

  s += (i + 1).toString() + ".jpg";
  return s;
}),
    names2 = new List.generate(185, (i) {
  String s = "/marvel_dc/DC/";
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
    names1.removeAt(6);
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
                .where('id', isEqualTo: 'MLDC')
                .getDocuments();
            var doc = qs.documents.first;
            doc.reference.updateData({'images': images});
          },
        ),
      ),
    );
  }
}
