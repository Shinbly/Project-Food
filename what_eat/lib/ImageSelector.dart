import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:whateat/APIs/GoogleCustomSearch.dart';
import 'package:whateat/Widgets/ImageWithThumbnail.dart';

class ImageSelector extends StatefulWidget {
  @override
  _ImageSelectorState createState() => _ImageSelectorState();
}

class _ImageSelectorState extends State<ImageSelector> {

  FutureOr<FirebaseFirestore> firestore;

  FutureOr<Map<String,dynamic>> futureFoodToModify;
  Map<String,dynamic> foodToModify;

  int current_food = 0;


  bool useCached = false;
  GoogleCustomSearch gcs;

  @override
  void initState() {
    super.initState();

    gcs = GoogleCustomSearch();
    firestore = Firebase.initializeApp().then((app){
      return FirebaseFirestore.instance;

    });

    futureFoodToModify = Future.value(firestore).then((FirebaseFirestore instance) async {
      Map<String,dynamic> foodToModify = {};
      await instance.collection("foods").get().then((docs) async {
        List<dynamic> foodDocs = docs.docs;
        for(int i=0; i< foodDocs.length ; i++){
          QueryDocumentSnapshot currentDoc = foodDocs[i];
          dynamic data = currentDoc.data();
          if((data['verifiedImage'] != null && data['verifiedImage'] == false ) || data['images'] == null || (data['images'] != null && data['images'].length < 5)){
            foodToModify[currentDoc.id] = data;
          }
        }
      });
      await instance.collection("suggested_foods").get().then((docs) async {
        List<dynamic> foodDocs = docs.docs;
        for(int i=0; i< foodDocs.length ; i++){
          QueryDocumentSnapshot currentDoc = foodDocs[i];
          dynamic data = currentDoc.data();
          if((data['verifiedImage'] != null && data['verifiedImage'] == false ) || data['images'] == null || (data['images'] != null && data['images'].length < 5)){
            foodToModify[currentDoc.id] = data;
          }
        }
      });
      return foodToModify;
    });
  }

  FutureOr<Map<String,dynamic>> getCurrentFood() async {
    if(foodToModify == null)
      foodToModify = await Future.value(futureFoodToModify);
    if(current_food < foodToModify.length) {
      Map<String,dynamic> data = foodToModify[foodToModify.keys.elementAt(current_food)];
      List images = data["images"] ?? [];
      images.addAll(await gcs.searchImage('${data["label"]} dish', nb_images: (10 - images.length)));
      data["images"] = images;
      return data;
    }else{
      return {'empty' : true};
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Image Selector"),),
      body: FutureBuilder(
        future: Future.value(getCurrentFood()),
        builder: (context, foodSnapshot){
          if(foodSnapshot.connectionState == ConnectionState.done){

            dynamic currentFood = foodSnapshot.data();
            if(currentFood['empty']){
              return Text('No Pictures to Manage');
            }
            List<dynamic> images = currentFood["images"] ?? [];



            return Container(
              child: Column(
                children: [
                  Center(
                    child: Text(currentFood["label"]),
                  ),
                  GridView.count(
                      crossAxisCount: 2,
                      children: images.map((image) {
                        return Container(
                          width: MediaQuery.of(context).size.width *0.4,
                          height: MediaQuery.of(context).size.width *0.3,
                          child: InkWell(
                            onLongPress: (){
                              image["selected"] = true;
                            },
                            onTap: (){
                              image["selected"] = false;
                            },
                            child: Stack(
                              children: [
                                ImageThumbnail(
                                  width: MediaQuery.of(context).size.width *0.4,
                                  height: MediaQuery.of(context).size.width *0.3,
                                  image: image['full'],
                                  thumbnail: image['thumbnail'],
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width *0.4,
                                  height: MediaQuery.of(context).size.width *0.3,
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity( (image["selected"] != null && image["selected"] == true) ? 0.7 : 0.0)
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                  ),
                  RaisedButton(
                    child: Text("Valid"),
                    onPressed: (){
                      print(images);
                    },
                  )
                ],
              ),
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      )
    );
  }


}
