import 'dart:math';

import 'package:flutter/material.dart';

class Bubble extends StatelessWidget {
  String text;
  TextStyle style;
  Bubble(this.text, {this.style =const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 30,
      color: Colors.black
  )});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Arrow(color: Colors.black,),
        Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(100.0)),
                border: Border.all(
                    width: 3
                )
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                this.text,
                style: style,
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class Arrow extends StatelessWidget {
  final Color color;

  double width = 20.0;
  double height = 10;

  Arrow({this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: ClipRect(
        child: OverflowBox(
          maxWidth: width,
          maxHeight: height*2,
          child: Align(
            alignment: Alignment.topCenter,
            child: Transform.translate(
              offset: Offset(.0, height),
              child: Transform.rotate(
                angle: pi / 4,
                child: Container(
                  width: width,
                  height: height * 2,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
