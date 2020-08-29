import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:whateat/APIs/GoogleCustomSearch.dart';
import 'package:whateat/APIs/Wikipedia.dart';
import 'package:whateat/Widgets/ImageWithThumbnail.dart';

class ImageSelector extends StatefulWidget {
  @override
  _ImageSelectorState createState() => _ImageSelectorState();
}

class _ImageSelectorState extends State<ImageSelector> {

  FutureOr<FirebaseFirestore> firestore;

  FutureOr<Map<String,dynamic>> futureFoodToModify;
  Map<String,dynamic> foodToModify;

  int offset = 0;
  int current_food = 0;
  int currentLoadedFood = -1;
  int nb_selected = 0;

  bool useCached = false;
  GoogleCustomSearch gcs;

  String searchText = "";

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
          if((data['verifiedImage'] != null && data['verifiedImage'] == false ) || data['images'] == null || (data['images'] != null && data['images'].length < 3)){
            foodToModify[currentDoc.id] = data;
          }
        }
      });
      await instance.collection("suggested_foods").get().then((docs) async {
        List<dynamic> foodDocs = docs.docs;
        for(int i=0; i< foodDocs.length ; i++){
          QueryDocumentSnapshot currentDoc = foodDocs[i];
          dynamic data = currentDoc.data();
          if((data['verifiedImage'] != null && data['verifiedImage'] == false ) || data['images'] == null || (data['images'] != null && data['images'].length < 3)){
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
      List wikiImages = await Wiki.searchImages(data["label"]);
      if( ! images.any((element) => element["source"] == "wikipedia"))
        images.addAll(wikiImages);

      foodToModify[foodToModify.keys.elementAt(current_food)]["images"] = images;
      return data;
    }else{
      return {'empty' : true};
    }
  }

  Future setImages(List images) async {
    images = images.map((value) {
      dynamic image = {'full': value['full'], 'thumbnail':value['thumbnail']};
      return image;
    }).toList();
    await Future.value(firestore).then((FirebaseFirestore instance) async {
      await instance.collection("foods").doc(foodToModify.keys.elementAt(current_food)).update({'images': images, 'verifiedImage' : true});
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Image Selector"),),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: FutureBuilder(
              future: Future.value(getCurrentFood()),
              builder: (context, foodSnapshot){
                if(foodSnapshot.connectionState == ConnectionState.done || current_food == currentLoadedFood){
                  dynamic currentFood;
                  if (currentLoadedFood == current_food){
                    currentFood = foodToModify[foodToModify.keys.elementAt(current_food)] ?? {'empty':true};
                  }else{
                    currentFood= foodSnapshot.data;
                    currentLoadedFood = current_food;
                  }
                  if(currentFood['empty'] ?? false){
                    return Center(child: Text('No Pictures to Manage', style: TextStyle( fontSize: 20),));
                  }
                  List<dynamic> images = currentFood["images"] ?? [];

                  return Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(currentFood["label"], style: TextStyle( fontSize: 25, fontWeight: FontWeight.bold),),
                        ),
                        Text("select the images you whant to keep", style: TextStyle( fontSize: 20),),
                        TextField(
                          onChanged: (value) => this.searchText = value,
                          
                        ),
                        Container(
                          height: MediaQuery.of(context).size.width,
                          child: GridView.count(
                            
                              crossAxisCount: 3,
                              children: images.map((dynamic image) {
                                double width = MediaQuery.of(context).size.width *0.3;
                                double height = MediaQuery.of(context).size.width * 0.3;

                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    width: width,
                                    height: height,
                                    child: InkWell(
                                      onTap: (){

                                        if(image["selected"] == null || image["selected"] == "0"){
                                          print("selected");
                                          image["selected"] = "1";
                                          nb_selected ++;
                                        }else{
                                          print("unselected");

                                          image["selected"] = "0";
                                          nb_selected --;
                                        }
                                        setState(() {});

                                      },
                                      child: Stack(
                                        children: [
                                          ImageThumbnail(
                                            width: width,
                                            height: height,
                                            image: NetworkImage(image['full']),
                                            thumbnail:  image["thumbnail"] != null ? image["thumbnail"].contains("data:image") ? MemoryImage(base64Decode(image["thumbnail"].split(',').removeLast())) : NetworkImage(image["thumbnail"]) : null,
                                            fit: BoxFit.cover,
                                          ),
                                          Container(
                                            width: width,
                                            height: height,
                                            decoration: BoxDecoration(
                                              color: Colors.blueAccent.withOpacity( (image["selected"] != null && image["selected"] == "1") ? 0.5 : 0.0)
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),

                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top : 8.0, bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              RaisedButton(
                                child: nb_selected >= 3 ? Text("Validation of the pictures") : Text("Load more Picture"),
                                onPressed: () async {
                                  Map<String,dynamic> data = foodToModify[foodToModify.keys.elementAt(current_food)];
                                  List images = data["images"] ?? [];
                                  images.removeWhere((element) => element["selected"] == null || element["selected"] == "0");
                                  if(images.length >= 3){
                                    await setImages(images);
                                    setState(() {
                                      current_food +=1;
                                      nb_selected = 0;
                                    });
                                  }else{
                                    Random r = new Random();
                                    images.addAll(await gcs.searchImage('${(searchText!= null && searchText.length > 4 ) ? searchText : data["label"] } dish', nb_images: (6 - images.length), offset: offset));
                                    offset += 6;
                                    data["images"] = images;
                                    foodToModify[foodToModify.keys.elementAt(current_food)] = data;
                                    setState(() {
                                    });
                                  }
                                },
                              ),
                              RaisedButton(
                                child: Text("Next"),
                                onPressed: () async {
                                  setState(() {
                                    current_food +=1;
                                    nb_selected = 0;
                                    offset = 0;
                                  });
                                },
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }
                return Center(child: CircularProgressIndicator());
              },
            ),
        ),
        ),
      );
  }


}
