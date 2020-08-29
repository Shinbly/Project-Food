import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:whateat/APIs/GoogleCustomSearch.dart';
import 'package:whateat/APIs/Spoonacular.dart';
import 'package:whateat/Widgets/ImageWithThumbnail.dart';



class Result extends StatefulWidget {
  String result;
  String id;
  FutureOr<CollectionReference> foods;
  String collectionName = 'foods';
  bool useCached = false;
  GoogleCustomSearch gcs = GoogleCustomSearch();

  ///map with full for fullsize images and thumbnail for thumbnails image
  FutureOr<List<Map<String,ImageProvider>>> fetchedImages;

  Result(this.result, this.id){
    foods = initDB();
  }

  Future<CollectionReference> initDB() async {
    await Firebase.initializeApp();
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    return firestore.collection(collectionName);
  }

  @override
  _ResultState createState() => _ResultState();
}

class _ResultState extends State<Result> {


  @override
  initState(){
    super.initState();
  }

  Future<void> signalPictures() async {
    (await Future.value(widget.foods)).doc(widget.id).update({'verifiedImage':false});
  }

  Future<Map<String, dynamic>> getDoc() async {
    return await Future.value(widget.foods).then((foods) async {
      return await foods.doc(widget.id).get().then((DocumentSnapshot documentSnapshot) async {
        Map<String, dynamic> data = {};
        bool exist = false;
        if (documentSnapshot.exists) {
          exist = true;
          data = documentSnapshot.data();
        } else {
          data["label"] = widget.result;
        }
        if(!exist || data["images"] == null){
          data['images'] = await widget.gcs.searchImage("${widget.result} dish", cached: false) ?? null;
          return await foods.doc(widget.id).set(data).then((value) {
            return data;
          }).catchError((error) => print("Failed to add food: $error"));
        }else{
          return data;
        }
      });
    });
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }



  Future<void> uploadPic(context) async {
    ImagePicker imagePicker = ImagePicker();
    PickedFile image;
    PermissionStatus permisionStorage = await Permission.storage.request();
    bool autorised = permisionStorage.isGranted;
    if (autorised) {
      //get the image
      PickedFile _result = await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Scaffold(
              backgroundColor: Colors.black12.withOpacity(0.1),
              body: Stack(
                children: <Widget>[
                  AlertDialog(
                    titlePadding: EdgeInsets.zero,
                    title: Container(
                      color: Colors.grey[800],
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text("Add A Image", style: TextStyle(
                              fontSize: 20,

                            )),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.white,),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                    content: Text("With your Camera or the Gallery"),
                    actions: <Widget>[
                      Container(
                        width: 400,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 375,
                              child: RaisedButton(
                                onPressed: () async {
                                  await imagePicker.getImage(source: ImageSource.camera).then((image) {
                                    Navigator.pop(context, image);
                                  });
                                },
                                color: Color(0xFF8F1718),
                                textColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                child: Text("Camera", style: TextStyle(
                                    fontSize: 20.0
                                ),),
                              ),
                            ),
                            Container(
                              width: 375,
                              child: RaisedButton(
                                onPressed: () async {
                                  await imagePicker.getImage(source: ImageSource.gallery).then((image) {
                                    Navigator.pop(context, image);
                                  });
                                },
                                color: Color(0xFF8F1718),
                                textColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                child: Text("Gallery", style: TextStyle(
                                    fontSize: 20.0
                                ),),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
      );

      FirebaseStorage _storage = FirebaseStorage.instance;
      //Create a reference to the location you want to upload to in firebase
      StorageReference reference = _storage.ref().child("${widget.collectionName}/${widget.id}");
      //Upload the file to firebase
      StorageUploadTask uploadTask = reference.putFile(File(image.path));
      await uploadTask.onComplete.then((StorageTaskSnapshot snapshot) {
        snapshot.ref.getDownloadURL().then((downloadUrl) => {
          Future.value(widget.foods).then((foods){
            foods.doc(widget.id). get ().then((DocumentSnapshot documentSnapshot){
            Map<String, dynamic> data = {};
            data["photoUrl"] = downloadUrl;
            foods.doc(widget.id).set(data).then((value) {
            setState(() {});
            }).catchError((error) => print("Failed to add food: $error"));
            });
          })
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.result),
      ),
      body: SingleChildScrollView(
        child:
        FutureBuilder(
          future: Future.value(getDoc()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return StreamBuilder(
                  stream: FirebaseFirestore.instance.collection(
                      widget.collectionName)
                      .doc(widget.id.toString())
                      .snapshots(),
                  builder: (context, foodSnapshot) {
                    if (foodSnapshot.hasData && foodSnapshot.data != null) {
                      DocumentSnapshot foodDoc = foodSnapshot.data;
                      Map<String, dynamic> foodData = foodDoc.data();
                      List<dynamic> images = foodData["images"];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 20.0, bottom: 15),
                                child: (images != null) ? (images.length > 1)
                                    ? CarouselSlider(
                                  items: images.map((image) {
                                    return ImageThumbnail(
                                      image: NetworkImage(image["full"]),
                                      thumbnail:  image["thumbnail"] != null ? image["thumbnail"].contains("data:image") ? MemoryImage(base64Decode(image["thumbnail"].split(',').removeLast())) : NetworkImage(image["thumbnail"]) : null,
                                      height: 200,
                                      width: 300,
                                      fit: BoxFit.cover,
                                    );
                                  }).toList(),
                                  options: CarouselOptions(
                                      autoPlayCurve: Curves.decelerate,
                                      autoPlay: true,
                                      height: 200,
                                      initialPage: new Random().nextInt(images.length),
                                  ),
                                )
                                    : (images.length == 1) ?
                                ImageThumbnail(
                                  image: NetworkImage(images[0]["full"]),
                                  thumbnail: images[0]["thumbnail"] != null ? NetworkImage(images[0]["thumbnail"]) : null,
                                  height: 200,
                                  width: 300,
                                  fit: BoxFit.cover,
                                ) :

                                Container() :
                                Container()


                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(top: 20),
                                child: ListTile(
                                    title: Text(
                                        "Find a ${foodData["label"]} restaurant"),
                                    leading: Image.asset("assets/restaurant.png", width: 50, height: 50,),
                                    onTap: () {
                                      String googleUrl = 'https://www.google.com/maps/search/?api=1&query=${foodData["label"]}';
                                      _launchURL(googleUrl);
                                    }),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 20),
                                child: ListTile(
                                    title: Text(
                                        "Get recipes for ${foodData["label"]}"),
                                    leading: Image.asset("assets/recipe-book.png", width: 50, height: 50,), //Icon(Icons.receipt),
                                    onTap: () {
                                      //Spoonacular.searchFood(foodData["label"]);
                                      String allrecipesUrl = 'https://www.allrecipes.com/search/?wt=${foodData["label"]}';
                                      _launchURL(allrecipesUrl);
                                    }),
                              ),




                              Container()
                            ],
                          ),
                          /*ListTile(
                              title: Text(""),
                              subtitle: Text("the pictres are not right"),
                              onTap: () {
                                signalPictures();
                              }),*/
                        ],
                      );
                    } else {
                      return Center(child: CircularProgressIndicator());
                    }
                  }
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
