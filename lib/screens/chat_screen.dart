import 'package:chat/screens/image_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as Path;

class ChatScreen extends StatefulWidget {
  final String name;
  final String senderUid;
  final String receiverUid;

  ChatScreen({this.name, this.senderUid, this.receiverUid});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  CollectionReference _colRef;
  //DocumentReference _docRef;
  File _image;

  TextEditingController _controller;
  String message; //Store url in case of image

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    message = "";
    _colRef = FirebaseFirestore.instance.collection('messages');
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    await imagePicker.getImage(source: ImageSource.gallery).then((image) {
      setState(() {
        _image = File(image.path);
      });
    });
    uploadPic();
  }

  Future uploadPic() async {
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('/chats/${Path.basename(_image.path)}');
    UploadTask uploadTask = ref.putFile(_image);
    await uploadTask.whenComplete(() {
      print('File uploaded');
      ref.getDownloadURL().then((url) {
        setState(() {
          message = url; //message will store image in case of url
          submit(messageType: 'image');
        });
      });
    });
  }

  void submit({String messageType}) {
    if (messageType == 'text') {
      setState(() {
        message = _controller.text;
        _controller.clear();
      });
    }
    Timestamp time = Timestamp.now();
    send(
        sender: widget.senderUid,
        receiver: widget.receiverUid,
        messageType: messageType,
        time: time,
        message: message);
    send(
        sender: widget.receiverUid,
        receiver: widget.senderUid,
        messageType: messageType,
        time: time,
        message: message);
  }

  void send(
      {String sender,
      String receiver,
      String messageType,
      String message,
      Timestamp time}) {
    _colRef.doc(sender).collection(receiver).doc().set({
      'message': message,
      'senderUid': widget.senderUid,
      'receiverUid': widget.receiverUid,
      'timestamp': time,
      'type': messageType,
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
                icon: Icon(Icons.attachment),
                onPressed: () {
                  getImage();
                },
              ),
              IconButton(
                onPressed: () {
                  submit(messageType: "text");
                },
                icon: Icon(
                  Icons.send,
                  //color: Colors.deepPurple,
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
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            itemCount: snapshot.data.docs.length,
            reverse: true,
            itemBuilder: (context, index) {
              Timestamp timeStamp = snapshot.data.docs[index]['timestamp'];
              String time = timeStamp.toDate().toString().substring(11, 16);
              bool isSender =
                  snapshot.data.docs[index]['senderUid'] == widget.senderUid;
              bool isImage = snapshot.data.docs[index]['type'] == 'image';
              return Row(
                mainAxisAlignment:
                    isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  isImage
                      ? imageContainer(
                          url: snapshot.data.docs[index]['message'])
                      : textContainer(
                          isSender: isSender,
                          time: time,
                          textMessage: snapshot.data.docs[index]['message']),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget imageContainer({String url}) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ImageScreen(tag: url, url: url)));
      },
      child: Hero(
        tag: url,
        child: Container(
          //padding: const EdgeInsets.all(10.0),
          margin: const EdgeInsets.symmetric(vertical: 5.0),
          height: 200,
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            border: Border.all(
              width: 3.0,
              color: Colors.grey,
            ),
            image: DecorationImage(
              fit: BoxFit.cover,
              image: NetworkImage(
                url,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget textContainer({bool isSender, String textMessage, String time}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: isSender ? Colors.grey : Colors.deepPurple,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10.0),
          bottomRight: Radius.circular(10.0),
          topLeft: isSender ? Radius.circular(10.0) : Radius.circular(0.0),
          topRight: isSender ? Radius.circular(0.0) : Radius.circular(10.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 250,
            child: Text(
              textMessage,
              //snapshot.data.docs[index]['message'],
              style: TextStyle(
                fontSize: 18.0,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: isSender ? Colors.black : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String id;
  final String message;

  Message({this.id, this.message});
}
