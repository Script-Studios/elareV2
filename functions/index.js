const functions = require("firebase-functions");

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

const admin = require("firebase-admin");
admin.initializeApp(functions.config().firebase);

exports.addUser = functions.https.onCall((data, context) => {
  const users = admin.firestore().collection("users");
  return users.add({
    name: data["name"],
    email: data["email"]
  });
});
exports.newGame = functions.https.onCall((data, context) => {
  const themes = admin.firestore().collection("themes");
  const games = admin.firestore().collection("games");
  
});
