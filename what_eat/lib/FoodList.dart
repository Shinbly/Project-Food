import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:whateat/Widgets/ImageWithThumbnail.dart';
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
  bool isInit = false;

  bool searchMode = false;
  String searchValue;


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
        title: searchMode ?
        Container(
          width: MediaQuery.of(context).size.width * 0.7,

          child: Row(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.3, child: Text('All meals')
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.all(Radius.circular(8))
                ),
                width: MediaQuery.of(context).size.width * 0.4,
                child: TextField(
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                  onChanged: (value){
                    searchValue = value;
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ) :
        Center(child: Text('All meals',style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold))),
        actions: [
          InkWell(
            onTap: (){
              if(searchMode){
                searchValue = null;
                searchMode = false;
              }
              else{
                searchMode = true;
              }
              setState(() {
              });
            },
            child:searchMode ?  Icon(Icons.clear) :  Icon(Icons.search),
          ),
        ],

      ),
      body: Padding(
        padding: const EdgeInsets.only(top:5),
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child : FutureBuilder(
            future: Future.wait([init]),
            builder: (context, snapshot){
              if(snapshot.connectionState == ConnectionState.done || isInit){
                isInit = true;

                return StreamBuilder(
                    stream: firestore.collection(collectionName).orderBy("label").snapshots(),
                    builder: (context, foodsSnapshot){
                      if(foodsSnapshot.hasData && foodsSnapshot.data != null){
                        int nbFood = foodsSnapshot.data.documents.length;
                        List displayedFood = foodsSnapshot.data.documents;
                        if(searchValue != null){
                          displayedFood = displayedFood.map((doc){
                            DocumentSnapshot foodDoc = doc;
                            Map<String,dynamic> foodData = foodDoc.data();
                            String label = foodData['label'];
                            if(label.contains(searchValue)){
                              return foodDoc;
                            }else{
                              return null;
                            }
                          }).toList();
                          displayedFood.removeWhere((element) => element == null);
                        }

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
                              itemCount: displayedFood.length,
                              itemBuilder: (context, index) {
                                DocumentSnapshot foodDoc = displayedFood[index];
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
                                    ImageThumbnail(
                                      thumbnail: foodData["images"][0]["thumbnail"] != null ?  foodData["images"][0]["thumbnail"].contains("data:image") ?
                                        MemoryImage(base64Decode(foodData["images"][0]["thumbnail"].split(',').removeLast())) :
                                        NetworkImage(foodData["images"][0]["thumbnail"]) : null,
                                      image: NetworkImage(foodData["images"][0]["full"]),
                                      fit: BoxFit.cover,
                                      height: 100,
                                      width: 100,
                                    ) :
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
