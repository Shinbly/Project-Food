import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class Suggestion extends StatefulWidget {

  FirebaseFirestore firestore;
  String collectionName = 'suggested_foods';
  Future init;

  Suggestion() {
    init = Firebase.initializeApp().then((app){
      firestore = FirebaseFirestore.instance;
      return ;
    });
  }

  @override
  _SuggestionState createState() => _SuggestionState();
}

class _SuggestionState extends State<Suggestion> {

  @override
  void initState() {

  }


  @override
  Widget build(BuildContext context) {
    return Container();
  }

}
