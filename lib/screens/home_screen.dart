import 'package:chat/screens/chat_screen.dart';
import 'package:chat/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  List<DocumentSnapshot> documents;

  @override
  initState() {
    super.initState();
    user = _auth.currentUser;
    _colRef = FirebaseFirestore.instance.collection('users');
    _docRef = _colRef.doc(user.uid);
    checkIfDocExists();
  }

  checkIfDocExists() async {
    var doc = await _docRef.get();
    if (!doc.exists) {
      uploadUserInfo();
    }
  }

  uploadUserInfo() async {
    await _colRef.doc(user.uid).set({
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
          // ListTile(
          //   title: Text(
          //     "Theme",
          //     style: TextStyle(
          //       color: Colors.deepPurpleAccent,
          //     ),
          //   ),
          // ),
          ListTile(
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
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: UserSearch());
            },
          ),
        ],
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
        //future: _colRef.get(),
        future: _colRef.get(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          documents = snapshot.data.docs;
          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
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

class UserSearch extends SearchDelegate {
  CollectionReference _colRef = FirebaseFirestore.instance.collection('users');

  @override
  String get searchFieldLabel => 'Search Users';

  @override
  TextStyle get searchFieldStyle => TextStyle(
        color: Colors.white,
        fontSize: 18.0,
      );

  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context).copyWith(
      textTheme: TextTheme(
        headline6: TextStyle(
          color: Colors.white,
        ),
      ),
    );
    assert(theme != null);
    return theme;
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User user;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.cancel),
        onPressed: () {
          query = "";
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
      future: _colRef.get(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        List<DocumentSnapshot> documents = snapshot.data.docs;

        user = _auth.currentUser;
        return ListView.builder(
          itemCount: documents.length,
          itemBuilder: (context, index) {
            return (documents[index]['name']
                        .toString()
                        .toLowerCase()
                        .contains(query.toLowerCase()) &&
                    !(documents[index].id == user.uid))
                ? _customTile(
                    context: context,
                    name: documents[index]['name'],
                    receiverUid:
                        documents[index].id, // Receiver is another person
                    senderUid: user.uid, //Sender is the user himself
                    photoUrl: documents[index]['photoUrl'],
                  )
                : Container();
          },
        );
      },
    );
  }
}
