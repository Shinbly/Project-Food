import 'dart:math';
import 'dart:io';
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

  Future init;

  @override
  void initState() {
    super.initState();
    print("ok init state");
    try {
      init = Future.wait([loadJson('assets/decisionTree.json').then((Map<dynamic, dynamic> dataTree ){
        this.treeClassifier = DecisionTreeClassifier.fromMap(dataTree);
      }),
      loadJson('assets/classes.json').then((Map<dynamic, dynamic> data){
        classes = data;
        nb_classes = classes.length;
      }),
      loadJson('assets/features.json').then((Map<dynamic, dynamic> data ){
        features = data;
        nb_features = features.length;
        input = List(nb_features);
        print(input);
        nextFeatures();
      })]).then((value) => print('init'));
    }catch(e){
      print("error $e");
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
    print(question == 1 ? "yes" : "no");
    if(currentQuestion == question && currentFeatureIndex == next_key){
      setState(() {
        result = -2;
      });
    }else{
      setState(() {
        currentFeatureIndex = next_key;
        currentQuestion = question;
      });
    }
  }

  Future<Map<dynamic, dynamic>> loadJson(String path) async {
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
    double nullImportance = 0;
    List<double> test = [];
    for(int i = 0 ; i < input.length; i++){
      if(input[i] == null || input[i] == 2){
        nb_null++;
        nullImportance += features[i.toString()]["features_importance"];
      }
    }
    for(int i = 0 ; i < input.length; i++){
      if(input[i] == null){
        test.insert(i,((1.0/nullImportance)* features[i.toString()]["features_importance"]) );
      }else{
        test.insert(i,input[i].ceilToDouble());
      }
    }
    print(test);
    print("actual prediction : ${this.classes[treeClassifier.predict(test).toString()]}");
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

  void reset(){
    setState(() {
      this.result = -1;
      this.input = List(nb_features);
      this.infos = [];
      nextFeatures();
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
      body: FutureBuilder(
        future: Future.value(init),
        builder: (context, snapshot){
          if(snapshot.connectionState == ConnectionState.done){
            return Container(
              child: (this.result == -1 ) ? Column(
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
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          RaisedButton(
                            child:Text('Yes'),
                            onPressed: (){setValue(1);},
                          ),
                          /*RaisedButton(
                    child:Text('Yes and No'),
                    onPressed: (){setValue(2);},
                  ),*/
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
                child: (result != -2 ) ?
                Column(
                  children: <Widget>[
                    Text("the Result is ${this.classes[result.toString()]['label']}", style: TextStyle(fontSize: 30),),
                    IconButton(icon: Icon(Icons.send, color: Colors.primaries.first,), onPressed: (){
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context){
                            return Result(this.classes[result.toString()]['label'], result.toString());
                          }
                      ));
                    }),
                    IconButton(icon: Icon(Icons.refresh, color: Colors.deepOrange,), onPressed: reset),
                  ],
                ) :
                Column(
                  children: <Widget>[
                    Text("the Result are :  ${infos.join('\n')}", style: TextStyle(fontSize: 30),),
                    IconButton(icon: Icon(Icons.refresh, color: Colors.deepOrange,), onPressed: reset)

                  ],
                )    ,
              ),
            );
          }else{
            return Center(child : CircularProgressIndicator());
          }
        },
      )
    );
  }

}
