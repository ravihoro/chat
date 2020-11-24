import 'package:flutter/material.dart';

class ImageScreen extends StatelessWidget {
  final String tag;
  final String url;

  ImageScreen({this.tag, this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InteractiveViewer(
        child: Center(
          child: Hero(
            tag: tag,
            child: Image.network(
              url,
            ),
          ),
        ),
      ),
    );
  }
}
