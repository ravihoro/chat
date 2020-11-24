import 'package:chat/screens/image_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as Path;
import 'package:file_picker/file_picker.dart';
//import 'package:cached_network_image/cached_network_image.dart';

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
  //File _image;
  File _file;
  String fileName;

  TextEditingController _controller;
  String message; //Store url in case of image

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    message = "";
    _colRef = FirebaseFirestore.instance.collection('messages');
  }

  showBottomSheet({@required BuildContext context}) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Wrap(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 20.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(Icons.pages),
                            onPressed: () {
                              getDocument();
                            },
                          ),
                          Text(
                            'Documents',
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(Icons.camera),
                            onPressed: () {
                              getImage(source: 'camera');
                            },
                          ),
                          Text(
                            'Camera',
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(Icons.photo_size_select_actual_rounded),
                            onPressed: () {
                              getImage(source: 'gallery');
                            },
                          ),
                          Text(
                            'Gallery',
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(Icons.audiotrack),
                            onPressed: () {},
                          ),
                          Text(
                            'Audio',
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(Icons.location_on),
                            onPressed: () {},
                          ),
                          Text(
                            'Location',
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(Icons.contact_page),
                            onPressed: () {},
                          ),
                          Text(
                            'Contacts',
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                ],
              )
            ],
          );
        });
  }

  Future getDocument() async {
    await FilePicker.getFile().then((file) {
      setState(() {
        _file = file;
      });
    });
    Navigator.of(context).pop();
    upload(messageType: 'document');
  }

  Future getImage({@required String source}) async {
    ImagePicker imagePicker = ImagePicker();
    if (source == 'gallery') {
      await imagePicker.getImage(source: ImageSource.gallery).then((image) {
        setState(() {
          //_image = File(image.path);
          _file = File(image.path);
        });
      });
    } else {
      await imagePicker.getImage(source: ImageSource.camera).then((image) {
        setState(() {
          //_image = File(image.path);
          _file = File(image.path);
        });
      });
    }
    Navigator.of(context).pop();
    upload(messageType: 'image');
  }

  Future upload({@required String messageType}) async {
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('/chats/${Path.basename(_file.path)}');
    fileName = Path.basename(_file.path);
    //print('File name is: ${Path.basename(_file.path)}');
    UploadTask uploadTask = ref.putFile(_file);
    await uploadTask.whenComplete(() {
      //print('File uploaded');
      ref.getDownloadURL().then((url) {
        setState(() {
          message = url; //message will store url in case of document
          submit(messageType: messageType, fileName: fileName);
        });
      });
    });
    //Navigator.of(context).pop();
  }

  // Future uploadPic() async {
  //   Reference ref = FirebaseStorage.instance
  //       .ref()
  //       .child('/chats/${Path.basename(_image.path)}');
  //   UploadTask uploadTask = ref.putFile(_image);
  //   await uploadTask.whenComplete(() {
  //     print('File uploaded');
  //     ref.getDownloadURL().then((url) {
  //       setState(() {
  //         message = url; //message will store url in case of image
  //         submit(messageType: 'image');
  //       });
  //     });
  //   });
  // }

  void submit({@required String messageType, String fileName}) {
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
      message: message,
      fileName: fileName,
    );
    send(
      sender: widget.receiverUid,
      receiver: widget.senderUid,
      messageType: messageType,
      time: time,
      message: message,
      fileName: fileName,
    );
  }

  void send({
    String sender,
    String receiver,
    String messageType,
    String message,
    Timestamp time,
    String fileName,
  }) {
    _colRef.doc(sender).collection(receiver).doc().set({
      'message': message,
      'senderUid': widget.senderUid,
      'receiverUid': widget.receiverUid,
      'timestamp': time,
      'type': messageType,
      'fileName': fileName ?? '',
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
                  //getImage();
                  showBottomSheet(context: context);
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
        //print(snapshot.data);
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
              String type = snapshot.data.docs[index]['type'];
              //bool isImage = snapshot.data.docs[index]['type'] == 'image';
              return Row(
                mainAxisAlignment:
                    isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  type == 'text'
                      ? textContainer(
                          isSender: isSender,
                          time: time,
                          textMessage: snapshot.data.docs[index]['message'],
                        )
                      : type == 'image'
                          ? imageContainer(
                              url: snapshot.data.docs[index]['message'])
                          : documentContainer(
                              url: snapshot.data.docs[index]['message'],
                              fileName: snapshot.data.docs[index]['fileName']),
                  // isImage
                  //     ? imageContainer(
                  //         url: snapshot.data.docs[index]['message'])
                  //     : textContainer(
                  //         isSender: isSender,
                  //         time: time,
                  //         textMessage: snapshot.data.docs[index]['message']),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget documentContainer({@required String url, @required String fileName}) {
    print(url);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      padding: const EdgeInsets.all(10.0),
      height: 50.0,
      //width: 200.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(
          width: 3.0,
          color: Colors.grey,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.file_present),
          SizedBox(
            width: 5.0,
          ),
          Text(
            fileName,
          ),
        ],
      ),
    );
  }

  Widget imageContainer({@required String url}) {
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
          clipBehavior: Clip.antiAlias,
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
          // child: CachedNetworkImage(
          //   placeholder: (context, url) => SizedBox(
          //       height: 100, width: 100, child: CircularProgressIndicator()),
          //   imageUrl: url,
          // ),
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
