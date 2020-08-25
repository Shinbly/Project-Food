import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'APIs/GoogleCustomSearch.dart';
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
  bool useCached = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    init = Firebase.initializeApp().then((app){
      firestore = FirebaseFirestore.instance;
      return ;

    });
    _scrollController = ScrollController();


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AllFood'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top:5),
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child : FutureBuilder(
            future: Future.wait([init]),
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
                                  child:  Center(
                                    child: Container(
                                    height: 1,
                                    width: MediaQuery.of(context).size.width * 0.8,
                                    decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3)
                                    ),
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
                                    height: 100,
                                    width: 100,
                                    child : foodData["images"] != null ?
                                    foodData["images"][0]["thumbnail"].contains("data:image") ?
                                      Image.memory(base64Decode(foodData["images"][0]["thumbnail"].split(',').removeLast()),fit: BoxFit.cover) :
                                      Image.network(foodData["images"][0]["thumbnail"],fit: BoxFit.cover) :
                                    Image.asset("assets/color_placeholder.png",fit: BoxFit.cover)
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
      ),
      );
  }
}
