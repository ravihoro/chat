import 'package:chat/screens/chat_screen.dart';
import 'package:chat/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DocumentReference _docRef;
  CollectionReference _colRef;
  QuerySnapshot result;
  User user;

  @override
  initState() {
    super.initState();
    user = _auth.currentUser;
    //getUserInfo();
    _colRef = FirebaseFirestore.instance.collection('users');
    _docRef = _colRef.doc(user.uid);

    //print(_docRef);
    //print(_docRef.snapshots() == null);
    checkIfDocExists();
    // print(user.uid);
    //uploadUserInfo();
    //checkIfDocExists();
  }

  checkIfDocExists() async {
    var doc = await _docRef.get();
    if (!doc.exists) {
      uploadUserInfo();
    }
  }

  getUserInfo() {
    _docRef = FirebaseFirestore.instance
        .collection('users')
        .doc('ravijohnhoro5@gmail.com');
    print(_docRef.id);
  }

  uploadUserInfo() async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': user.displayName,
      'email': user.email,
      'photoUrl': user.photoURL,
    }).catchError((e) {
      print(e.toString());
    });
  }

  Widget customDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountEmail: Text(user.email),
            accountName: Text(
              user.displayName,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage:
                  //AssetImage('assets/user.jpg')
                  NetworkImage(user.photoURL),
            ),
          ),
          ListTile(
            title: Text(
              "Theme",
              style: TextStyle(
                color: Colors.deepPurpleAccent,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text("Sign Out",
                style: TextStyle(color: Colors.deepPurpleAccent)),
            trailing: Icon(
              Icons.exit_to_app,
              color: Colors.deepPurpleAccent,
            ),
            onTap: () async {
              await signOut();
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginScreen()));
            },
          ),
        ],
      ),
    );
  }

  signOut() async {
    await GoogleSignIn().signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLogged', false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat App',
        ),
      ),
      // body: Column(
      //   children: [
      //     _customTile(context: context, name: "Ravi"),
      //     _customTile(context: context, name: "John"),
      //     _customTile(context: context, name: "Mark"),
      //   ],
      // ),
      body: FutureBuilder(
        future: _colRef.get(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          List<DocumentSnapshot> documents = snapshot.data.docs;
          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              //print(documents.length);
              //print('${documents[index].id} and ${user.uid}');
              //print(documents[index].id == user.uid);
              // return _customTile(
              //   context: context,
              //   name: documents[index]['name'],
              //   receiverUid: documents[index].id, // Receiver is another person
              //   senderUid: user.uid, //Sender is the user himself
              //   photoUrl: documents[index]['photoUrl'],
              // );
              if (documents[index].id == user.uid)
                return Container();
              else {
                return _customTile(
                  context: context,
                  name: documents[index]['name'],
                  receiverUid:
                      documents[index].id, // Receiver is another person
                  senderUid: user.uid, //Sender is the user himself
                  photoUrl: documents[index]['photoUrl'],
                );
              }
            },
          );
        },
      ),
      drawer: customDrawer(),
    );
  }

  Widget _customTile(
      {BuildContext context,
      String name,
      String receiverUid,
      String senderUid,
      String photoUrl}) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ChatScreen(
                  name: name,
                  senderUid: senderUid,
                  receiverUid: receiverUid,
                )));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
        child: Row(
          children: [
            Container(
              alignment: Alignment.center,
              height: 60.0,
              width: 60.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.0),
                color: Colors.grey,
                image: DecorationImage(
                  image: photoUrl == ""
                      ? AssetImage('assets/user.jpg')
                      : NetworkImage(photoUrl),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey,
              width: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
