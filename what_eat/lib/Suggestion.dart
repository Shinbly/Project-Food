import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Suggestion extends StatefulWidget {

  Future<FirebaseFirestore > firestore;
  String collectionName = 'suggested_foods';

  Suggestion() {
    firestore =  Firebase.initializeApp().then((app){
      return FirebaseFirestore.instance;
    });
  }

  @override
  _SuggestionState createState() => _SuggestionState();
}

class _SuggestionState extends State<Suggestion> {
  FutureOr<Map<String,dynamic>> futureQuestions;
  Map<String,dynamic> questions;

  Map<String, String> suggestedFoodValue = {};
  String suggestedName = '';

  int nbQuestions;


  @override
  void initState() {

    futureQuestions = Future.value(widget.firestore).then((FirebaseFirestore instance){
      return instance.collection("questions").get().then((docs){
        List<dynamic> questionsDoc = docs.docs;
        Map<String,dynamic> questions = {};
        nbQuestions = questionsDoc.length;
        for(int i=0; i< nbQuestions;i++){
          QueryDocumentSnapshot currentDoc = questionsDoc[i];
          questions[currentDoc.id] = currentDoc.data();

        }
        return questions;
      });
    });

  }

  Future<bool> valid() async {
    Map<String,dynamic> questions = await Future.value(futureQuestions);
    return questions.keys.every((String key) => suggestedFoodValue[key] != null);
  }

  void upload() async {
    if(await valid()){
      await Future.value(widget.firestore).then((FirebaseFirestore instance) async {
        await instance.collection(widget.collectionName).add({
          'name' : suggestedName,
          'questions' : suggestedFoodValue,
        });
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: suggestedName == '' ? Text("Suggest Some Food") : Text("Fill the form for $suggestedName"),),
      body: FutureBuilder(
          future: Future.value(futureQuestions),
          builder: (context, questionsSnapchot){
            if(questionsSnapchot.connectionState == ConnectionState.done || questions != null ){
             if(questions == null && questionsSnapchot.data != null ) {
               questions = questionsSnapchot.data;
             }
             List ids = questions.keys.toList().map((e)=>int.parse(e)).toList();
             ids.sort();

             return ListView.separated(
               separatorBuilder: (context, index){
                 return Container(
                     width: MediaQuery.of(context).size.width,
                     height: 12,
                 );
               },
               itemCount: ids.length + 2,
               itemBuilder: (context, index) {
                 if (index == 0) {
                   return ListTile(
                     title: Text("What is the name of the food ?"),
                     subtitle: TextField(onChanged: (value)=> this.suggestedName = value),
                   );

                 }
                 if( index == ids.length + 1){
                   return Center(
                     child: Padding(
                       padding: const EdgeInsets.only(bottom: 20),
                       child: RaisedButton(
                         onPressed: (){

                           print( suggestedFoodValue);
                         },
                         child: Text("Submit"),
                       ),
                     ),
                   );
                 }
                   return ListTile(
                     title: Text(questions[ids[index - 1].toString()]["name"]),
                     subtitle: Container(
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceAround,
                         children: [
                           Container(
                             child: Column(
                               children: [
                                 Text("Yes"),

                                 Checkbox(
                                   value: suggestedFoodValue[ids[index - 1].toString()] != null &&
                                       suggestedFoodValue[ids[index - 1].toString()] == "yes",
                                   onChanged: (checked) {
                                     if (checked)
                                       setState(() {
                                         suggestedFoodValue[ids[index - 1]
                                             .toString()] = "yes";
                                       });
                                   },

                                 ),
                               ],
                             ),
                           ),
                           Container(
                             child: Column(
                               children: [
                                 Text("Yes and No"),
                                 Checkbox(
                                   value: suggestedFoodValue[ids[index - 1].toString()] != null &&
                                       suggestedFoodValue[ids[index - 1].toString()] == "yes and no",
                                   onChanged: (checked) {
                                     suggestedFoodValue[ids[index - 1].toString()] = checked ? "no" : null;
                                     setState(() {});
                                   },
                                 ),
                               ],
                             ),
                           ),
                           Container(
                             child: Column(
                               children: [
                                 Text("No"),
                                 Checkbox(
                                     value: suggestedFoodValue[ids[index - 1].toString()] != null &&
                                         suggestedFoodValue[ids[index - 1].toString()] == "no",
                                     onChanged: (checked) {
                                       suggestedFoodValue[ids[index - 1].toString()] = checked ? "no" : null;
                                       setState(() {});
                                     }

                                 ),
                               ],
                             ),
                           )

                         ],
                       ),
                     ),
                   );
                 }
             );
            }
            return Center(child: CircularProgressIndicator(),);
          }
      ),
    );
  }

}
