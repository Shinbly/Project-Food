import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:whateat/Result.dart';

class FoodList extends StatefulWidget {
  @override
  _FoodListState createState() => _FoodListState();
}

class _FoodListState extends State<FoodList> {

  FirebaseFirestore firestore;
  String collectionName = 'foods';
  ScrollController _scrollController;
  Future init;
	GoogleCustomSearch gcs;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    init = Firebase.initializeApp().then((app){
      firestore = FirebaseFirestore.instance;
      return ;
    });

    _scrollController = ScrollController();
		gcs = GoogleCustomSearch();


  }

  Future<void> setList() async {
    return await Future.value(init).then((res) async {
      return await rootBundle.loadString("assets/classes.json").then((String data) {
        Map<String, dynamic> foods = json.decode(data);
        foods.forEach((key, value) async {
          firestore.collection(collectionName).doc(key).get().then((DocumentSnapshot documentSnapshot) async {
            Map<String, dynamic> data = {};
            if (documentSnapshot.exists) {
              return data;
            } else {
              Map<String, dynamic> food = {};
              food["label"] = value['label'];
              return await firestore.collection(collectionName).doc(key).set(food).then((value) {
                return;
              }).catchError((error) => print("Failed to add food: $error"));
            }
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AllFood'),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child : FutureBuilder(
          future: Future.wait([init, setList()]),
          builder: (context, snapshot){
            if(snapshot.connectionState == ConnectionState.done){
              return StreamBuilder(
                  stream: firestore.collection(collectionName).snapshots(),
                  builder: (context, foodsSnapshot){
                    if(foodsSnapshot.hasData && foodsSnapshot.data != null){
                      int nbFood = foodsSnapshot.data.documents.length;
                      return ListView.separated(
                            controller: _scrollController,
                            separatorBuilder: (context, int) {
                              return Container(height: 10,
                                child:  Container(
                                height: 1,
                                width: MediaQuery.of(context).size.width * 0.8,
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3)
                                ),
                              ),);
                            },
                            itemCount: nbFood,
                            itemBuilder: (context, index) {
                              DocumentSnapshot foodDoc = foodsSnapshot.data.documents[index];
                              Map<String,dynamic> foodData = foodDoc.data();
                              String label = foodData['label'];

                              // showing food here
                              return ListTile(
                                onTap: (){
                                  Navigator.push(context, MaterialPageRoute(
                                      builder: (context){
                                        return Result(label, foodDoc.id);
                                      }
                                  ));
                                },
                                title: Text(label),
                                leading: Container(
                                  height: 20,
                                  width: 20,
                                  child : foodData['photoUrl'] != null ?
                                  Image.network(foodData["photoUrl"], fit: BoxFit.cover,) :
                                  FutureBuilder(
													          future: Future.value(gcs.getImage(foodData["label"])),
													          builder: (context, snapshot){
													            if(snapshot.connectionState == ConnectionState.done){
																				return FadeInImage(
                                          image: snapshot.data,
                                          placeholder: AssetImage("assets\color_placeholder.png"),
                                          fit: BoxFit.cover,
                                        );
																			}else{
													              return Image.asset("assets\color_placeholder.png",fit: BoxFit.cover);
																			}
																		}
																	),
                                ),

                              );
                            }
                            );
                    }else{
                      return Center(child: CircularProgressIndicator(),);
                    }
                  });
            }else{
              return Center(child: CircularProgressIndicator(),);
            }
          },
        )
        ),
      );
  }
}
