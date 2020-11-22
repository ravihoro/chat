import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String name;
  final String senderUid;
  final String receiverUid;

  ChatScreen({this.name, this.senderUid, this.receiverUid});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> messages = [
    Message(id: "1", message: "I'm also fine"),
    Message(id: "2", message: "I'm fine. How are you?"),
    Message(id: "1", message: "How are you?"),
    Message(id: "2", message: "Hello"),
    Message(id: "1", message: "Hi"),
  ];

  CollectionReference _colRef;
  DocumentReference _docRef;

  TextEditingController _controller;
  String message;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    message = "";
    _colRef = FirebaseFirestore.instance.collection('messages');
  }

  void submit() {
    setState(() {
      message = _controller.text;
      _controller.clear();
    });
    Timestamp time = Timestamp.now();
    _colRef.doc(widget.senderUid).collection(widget.receiverUid).doc().set({
      'message': message,
      'senderUid': widget.senderUid,
      'receiverUid': widget.receiverUid,
      'timestamp': time,
      'type': 'text',
    });

    _colRef.doc(widget.receiverUid).collection(widget.senderUid).doc().set({
      'message': message,
      'senderUid': widget.senderUid,
      'receiverUid': widget.receiverUid,
      'timestamp': time,
      'type': 'text',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Column(
        children: [
          Expanded(
            child: fetchMessages(context),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {},
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Send a message',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  submit();
                },
                icon: Icon(
                  Icons.send,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  StreamBuilder<QuerySnapshot> fetchMessages(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _colRef
          .doc(widget.senderUid)
          .collection(widget.receiverUid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data.docs.length == 0) {
          return Center(
            child: Text(
              "No messages",
            ),
          );
        }
        return ListView.builder(
          itemCount: snapshot.data.docs.length,
          reverse: true,
          itemBuilder: (context, index) {
            //print(snapshot.data.docs[index]['senderUid']);
            //print(widget.senderUid);
            return Row(
              mainAxisAlignment:
                  snapshot.data.docs[index]['senderUid'] == widget.senderUid
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 6.0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: snapshot.data.docs[index]['senderUid'] ==
                            widget.senderUid
                        ? Colors.grey
                        : Colors.deepPurpleAccent,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10.0),
                      bottomRight: Radius.circular(10.0),
                      topLeft: snapshot.data.docs[index]['senderUid'] ==
                              widget.senderUid
                          ? Radius.circular(10.0)
                          : Radius.circular(0.0),
                      topRight: snapshot.data.docs[index]['senderUid'] ==
                              widget.senderUid
                          ? Radius.circular(0.0)
                          : Radius.circular(10.0),
                    ),
                  ),
                  child: Text(
                    snapshot.data.docs[index]['message'],
                    style: TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class Message {
  final String id;
  final String message;

  Message({this.id, this.message});
}
