import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sklite/tree/tree.dart';
import 'dart:convert';

import 'package:whateat/Result.dart';

class ModelTree extends StatefulWidget {

  @override
  _ModelTreeState createState() => _ModelTreeState();
}

class _ModelTreeState extends State<ModelTree> {
/// data :
  /// model of the decision tree
  FutureOr<FirebaseFirestore> firestore;
  String modelCollectionName = 'model';
  String modelDocumentName = "tree";
  Future init;


  FutureOr<DecisionTreeClassifier> treeClassifier;
  FutureOr<Map<String,dynamic>> questions;
  FutureOr<Map<String,dynamic>> foods;
  ///nb of he questions
  int nbQuestions;
  ///nb of dishes predictable
  int nbFood;

  List<int> possibleFoodId = [];

  /// input to predict with the decision tree
  List<double> input = [];
  ///result of the prediction represent the id of a food
  int result = -1;
  /// probability of the result with all of the possible combination
  Map<int,double> proba = {};

  String infos ="";

  int currentFeatureIndex = -1;
  String currentQuestion ="";

  @override
  void initState() {
    super.initState();
      firestore = Firebase.initializeApp().then((app){
        return FirebaseFirestore.instance;
      });

      treeClassifier = Future.value(firestore).then((FirebaseFirestore instance){
        return instance.collection(modelCollectionName).doc(modelDocumentName).get().then((DocumentSnapshot doc){
          print("doc getted ");
          Map<String,dynamic> treeData = doc.data();
          String jsonString = treeData["jsonTree"].replaceAll("'", "\"");
          Map<String,dynamic> jsonTree = jsonDecode(jsonString);
          print('tree ${jsonTree.keys}');

          var tree =  DecisionTreeClassifier.fromMap(jsonTree);
          return tree;
        });
      });

      questions = Future.value(firestore).then((FirebaseFirestore instance){
        return instance.collection("questions").get().then((docs){
          List<dynamic> questionsDoc = docs.docs;
          Map<String,dynamic> questions = {};
          nbQuestions = questionsDoc.length;
          input = new List(nbQuestions);
          for(int i=0; i< nbQuestions;i++){

            QueryDocumentSnapshot currentDoc = questionsDoc[i];
            questions[currentDoc.id] = currentDoc.data();

          }
          print("question : ${questions.keys.length} ok");
          return questions;
        });
      });

      foods = Future.value(firestore).then((FirebaseFirestore instance){
        return instance.collection("foods").get().then((docs){
          List<dynamic> foodDocs = docs.docs;
          possibleFoodId = [];
          Map<String,dynamic> foods = {};
          nbFood = foodDocs.length;
          for(int i=0; i< nbFood; i++){
            QueryDocumentSnapshot currentDoc = foodDocs[i];
            foods[currentDoc.id] = currentDoc.data();
            possibleFoodId.add(int.parse(currentDoc.id));
          }
          print("foods : ${foods.keys.length} ok");

          return foods;
        });
      });

      init = Future.wait([Future.value(treeClassifier),Future.value(questions),Future.value(foods),nextQuestion()]);


  }

  Future sortProba() async {
    Map<String, dynamic> myFood = await Future.value(this.foods);
    List list = [];
    proba.forEach((key, value) {
      list.add('${value}% : ${myFood[key.toString()]['label']}');
    });
    if(list.length > 1 ){
      list.sort((a,b){
        return double.parse(b.split('%').first).compareTo( double.parse(a.split('%').first));
      });
    }
    infos = list.join('\n');
  }

  ///set the index to the next question with the bigest importance
  Future nextQuestion() async {
    print("getting next question ... ");
    Map<String, dynamic> myQuestions = await Future.value(this.questions);
    int next_key = 0;
    double importance = 0.0;
    double distribution = 0.0;
    //get the next question more important not ansered
    myQuestions.forEach((key,value) {
      Map<String, dynamic> questionData = value;
      double feature_importance = questionData['importance'];
      dynamic yesValues = questionData['yes'];
      dynamic noValues = questionData['no'];
      yesValues.removeWhere((value) =>  ! possibleFoodId.contains((value)));
      noValues.removeWhere((value) =>  ! possibleFoodId.contains((value)));
      int nb_yes= yesValues.length;
      int nb_no = noValues.length;
      double feature_distribution = 0.0;
      if(nb_no > nb_yes && nb_no>0)
        feature_distribution = nb_yes / nb_no;
      if(nb_yes > nb_no && nb_yes>0)
        feature_distribution = nb_no / nb_yes;


      print('${nb_yes} yes and ${nb_no} no');

      if (input[int.parse(key)] == null && ((feature_distribution != 0 && feature_distribution > distribution) || (feature_distribution == 0 && feature_importance > importance) )){
        distribution = feature_distribution;
        importance = feature_importance;
        next_key = int.parse(key);
      }
    });
    Map<String, dynamic> feature = myQuestions[next_key.toString()];
    String question = feature['name'];
    print(question);
    print("\nthe question : $question \nhave an importance of $importance and a current distribution of $distribution\n");

    return setState(() {
      currentFeatureIndex = next_key;
      currentQuestion = question;
    });
  }



  Future setValue(double response) async {
    print('set $currentQuestion to ${response == 1 ? "yes" : "no" }');
    input[currentFeatureIndex] = response;
    Map<String, dynamic> myFoods = await Future.value(this.foods);
    Map<String, dynamic> myQuestions = await Future.value(this.questions);
    Map<String, dynamic> currentQuestionData = myQuestions[currentFeatureIndex.toString()];
    if(response == 1){
      //if the response of the question is yes we remove the "no" of the possible responses
      possibleFoodId.removeWhere((element)=> currentQuestionData["no"].contains(element));
    }else{
      //if the response of the question is no we remove the yes of the possible responses
      possibleFoodId.removeWhere((element)=> currentQuestionData["yes"].contains(element));
    }
    infos = "the current possible food are :\n ${possibleFoodId.map((e) => myFoods[e.toString()]["label"]).toList().join(", ")}";
    if(possibleFoodId.length == 1){
      found(possibleFoodId[0]);
    }else{
      testValue();
    }
  }

  Future testValue() async {
    Map<String, dynamic> myFoods = await Future.value(this.foods);
    DecisionTreeClassifier tree = await Future.value(this.treeClassifier);
    int nb_null = 0;
    List<double> test = [];
    for(int i = 0 ; i < input.length; i++){
      if(input[i] == null || input[i] == 2){
        nb_null++;
      }
    }
    for(int i = 0 ; i < input.length; i++){
      if(input[i] == null){
        test.insert(i,(1.0/nb_null) );
      }else{
        test.insert(i,input[i].ceilToDouble());
      }
    }
    print(test);

    print("actual prediction : ${myFoods[tree.predict(test).toString()]["label"]}");
    int nb_case = pow(2, nb_null);
    print("nb of possibilityes  = $nb_case");
    if(nb_case < 5000 ) {
      List<List<double>> predictions = [];
      predictions.add(input);

      /// remove all the nulls values and replace them by copy with 0 and 1 insted of null or 2
      for (int i = 0; i < input.length; i++) {
        List<int> markIndexToDelete = [];
        for (int j = 0; j < predictions.length; j ++) {
          if (predictions[j][i] == null || predictions[j][i] == 2) {
            markIndexToDelete.add(j);
            List<double> copy = predictions[j].sublist(0);
            copy[i] = 0;
            predictions.add(copy.sublist(0));
            copy[i] = 1;
            predictions.add(copy.sublist(0));
          }
        }
        markIndexToDelete.sort();
        markIndexToDelete.reversed.forEach((index) {
          predictions.removeAt(index);
        });
      }
      print('test of ${predictions.length} case ');

      ///test the output of all the predictions, if it's the same, no need to ask more questions
      Map<int, double> results = {};
      predictions.forEach((element) {
        int output = tree.predict(element);
        if (results[output] == null) {
          results[output] = (100 / nb_case);
        } else {
          results[output] += (100 / nb_case);
        }
      });
      print(results);
      if (results.length == 1) {
        found(results.keys.first);

      }else{
        proba = results;
        sortProba();
        nextQuestion();
      }
    }else{
      nextQuestion();
    }

  }

  Future<void> found(int id ) async {
    Map<String, dynamic> myFood = await Future.value(this.foods);
    Navigator.push(context, MaterialPageRoute(builder: (context){return Result(myFood[id.toString()]["label"], id.toString());}));
  }

  void reset(){
    setState(() {
      this.result = -1;
      this.input = List(nbFood);
      this.infos = "";
      nextQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Model test'
        ),
      ),
      body: Center(
        child: FutureBuilder(
          future: Future.value(init),
          builder: (context, snapshot){
            if(snapshot.connectionState == ConnectionState.done){
              return Stack(
                  children: <Widget>[
                    Positioned(
                      top: 10,
                      child: Container(
                        height: 150,
                        width: MediaQuery.of(context).size.width,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Image.asset("assets/chef.png", width: 150, height: 150,),),
                      ),
                    ),
                    ///question :
                    Positioned(
                      top:  200,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                              this.currentQuestion,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 45,
                                color: Colors.black
                              ),
                              textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    ///answer
                    Positioned(
                      bottom: 30,
                      child: Container(
                          child : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              RaisedButton(
                                child:Text('Yes', style: TextStyle( fontSize: 15 , color: Colors.white),),
                                onPressed: (){setValue(1);},
                                color: Theme.of(context).primaryColor,
                              ),
                              /*RaisedButton(
                        child:Text('Yes and No'),
                        onPressed: (){setValue(2);},
                      ),*/
                              RaisedButton(
                                child:Text('No', style: TextStyle( fontSize: 15 , color: Colors.white),),
                                onPressed: (){setValue(0);},
                                color: Theme.of(context).primaryColor,

                              )
                            ],
                          )
                      ),
                    ),
                    /*
                    ///proba
                    Container(
                      child: Text(infos),
                    )*/
                  ],
                );
            }else{
              return Center(child : CircularProgressIndicator());
            }
          },
        ),
      )
    );
  }

}
