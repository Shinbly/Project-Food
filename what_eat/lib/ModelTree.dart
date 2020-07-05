import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sklite/tree/tree.dart';
import 'package:sklite/utils/io.dart';
import 'dart:convert';

class ModelTree extends StatefulWidget {

  @override
  _ModelTreeState createState() => _ModelTreeState();
}

class _ModelTreeState extends State<ModelTree> {
/// data :
  /// model of the decision tree
  DecisionTreeClassifier treeClassifier;
  Map<String,dynamic> features;
  Map<String,dynamic> classes;
  ///nb of he questions
  int nb_features;
  ///nb of dishes predictable
  int nb_classes;

  /// input to predict with the decision tree
  List<double> input = [];
  int result = -1;
  Map<int,double> proba = {};
  List<String> infos =[];

  int currentFeatureIndex = 0;
  String currentQuestion ="";


  _ModelTreeState() {
    try {
      loadJson('assets/decisionTree.json').then((dynamic dataTree ){
        this.treeClassifier = DecisionTreeClassifier.fromMap(dataTree);
      });
      loadJson('assets/classes.json').then((dynamic data){
        classes = data;
        print( 'classes : ${classes.length}');
        nb_classes = classes.length;
      });
      loadJson('assets/features.json').then((dynamic data ){
        features = data;
        nb_features = features.length;
        input = List(nb_features);
        print(input);
        nextFeatures();
      });
    }catch(e){
      print(e);
    }
  }

  sortProba(){
    infos = [];
    proba.forEach((key, value) {
      infos.add('${value}% : ${this.classes[key.toString()]['label']}');
    });
    if(infos.length > 1 ){
      infos.sort((a,b){
        return double.parse(b.split('%').first).compareTo( double.parse(a.split('%').first));
      });
    }
  }

  ///set the index to the next feature with the bigest features_importance
  nextFeatures(){ 
    int next_key = 0;
    double importance = 0.0;
    features.forEach((key, value) {
      Map<String,dynamic> feature = value;
      double feature_importance = feature['features_importance'];

      if(input[int.parse(key)] == null && feature_importance > importance){
        importance = feature_importance;
        next_key = int.parse(key);
      }
    });
    Map<String, dynamic> feature = this.features[next_key.toString()];
    String question = feature['feature_names'];
    print('set to $next_key question to : $question');
    setState(() {
      currentFeatureIndex = next_key;
      currentQuestion = question;
    });
  }

  dynamic loadJson(String path) async {
    String data = await rootBundle.loadString(path);
    return json.decode(data);
  }

  setValue(double i) {
    print('set $currentFeatureIndex to $i');
    input[currentFeatureIndex] = i;
    print("curent input : $input");
    testValue();
  }

  testValue(){
    int nb_null = 0;
    input.forEach((e){
      if(e == null || e == 2){
        nb_null++;
      }
    });
    int nb_case = pow(2, nb_null);
    print("nb of possibilityes  = $nb_case");
    if(nb_case < 1000 ) {
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
        int output = treeClassifier.predict(element);
        if (results[output] == null) {
          results[output] = (100 / nb_case);
        } else {
          results[output] += (100 / nb_case);
        }
      });
      print(results);
      if (results.length == 1) {
        setState(() {
          this.result = results.keys.first;
        });
      }else{
        proba = results;
        sortProba();
        nextFeatures();
      }
    }else{
      nextFeatures();
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Model test'
        ),
      ),
      body: (this.result < 0 ) ? Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          ///question :
          Container(
            child: Text(
              this.currentQuestion
            ),
          ),
          ///answer
          Container(
            child : Row(
              children: <Widget>[
                RaisedButton(
                  child:Text('Yes'),
                  onPressed: (){setValue(1);},
                ),
                RaisedButton(
                  child:Text('Yes and No'),
                  onPressed: (){setValue(2);},
                ),
                RaisedButton(
                  child:Text('No'),
                  onPressed: (){setValue(0);},
                )
              ],
            )
          ),
          ///proba
          Container(
            child: Text(infos.join('\n')),
          )
        ],
      ):
        Container(
          child: Column(
            children: <Widget>[
              Text("the Result is ${this.classes[result.toString()]['label']}", style: TextStyle(fontSize: 30),),
              IconButton(icon: Icon(Icons.refresh, color: Colors.deepOrange,), onPressed: (){
                setState(() {
                  this.result = -1;
                  this.input = List(nb_features);
                  nextFeatures();
                });
              })

            ],
          ),
        )
    );
  }

}
