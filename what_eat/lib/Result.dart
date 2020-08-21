import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:whateat/GoogleCustomSearch.dart';



class Result extends StatefulWidget {
  String result;
  String id;
  FutureOr<CollectionReference> foods;
  String collectionName = 'foods';
  FutureOr<dynamic> wikipediaPage;
  FutureOr<List<ImageProvider>> fetchedImages;

  Result(this.result, this.id){
    foods = initDB();
    fetchedImages = getImages();
  }

  FutureOr<List<ImageProvider>> getImages() async {
    GoogleCustomSearch gcs = GoogleCustomSearch();
    return gcs.searchImage("\"${this.result}\"", 5).then((value){
      List<dynamic> items = value["items"];
      List<dynamic> urls = items.map((item){
        return item["link"];
      }).toList();
      return urls.map((e) => NetworkImage(e.toString())).toList();
    });

    /*
      try {

        String titleQuery = this.result.split(' ').join('%20');
        if(retry)
          titleQuery = titleQuery.substring(0, titleQuery.length-1);
        String apiUrl = "https://en.wikipedia.org/w/api.php?action=query&titles=${titleQuery}&prop=images&format=json";
        print(apiUrl);
        return await http.get(apiUrl).then((rep) {
          List<Image> imageList = [];
          Map<String, dynamic> jsonData = jsonDecode(rep.body);
          List<dynamic> images = jsonData["query"]["pages"][jsonData["query"]["pages"].keys.first]["images"];
          List<Future<String>> urls;
          if(images != null && images.length> 0){
            urls = images.map((image) async {
              String title = image["title"];
              if (!title.contains('.svg')) {
                String mediaUrl = "https://en.wikipedia.org/w/api.php?action=query&titles=${title.split(' ').join('%20')}&prop=imageinfo&iiprop=url&format=json";
                dynamic mediaRep = await http.get(mediaUrl);
                dynamic jsonDataMedia = jsonDecode(mediaRep.body);
                String imageUrl = jsonDataMedia["query"]["pages"][jsonDataMedia["query"]["pages"].keys.first]["imageinfo"][0]["url"];
                return imageUrl;
              } else {
                return null;
              }
            }).toList();
            return Future.wait(urls).then((value) {
              List urls = value.sublist(0);
              urls.removeWhere((element) => element == null);
              print(urls);
              return urls.map((e) => NetworkImage(e)).toList();
            });
          }else{
            if(titleQuery.endsWith('s') && !retry){
              return getImages(retry: true);
            }
            return [];
          }
        });
      }catch(e){
        print(e);
        return [];
      }*/
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

  Future<Map<String, dynamic>> getDoc() async {
    return await Future.value(widget.foods).then((foods) async {
      return await foods.doc(widget.id).get().then((DocumentSnapshot documentSnapshot) async {
        Map<String, dynamic> data = {};
        if (documentSnapshot.exists) {
          data = documentSnapshot.data();
          return data;
        } else {
          data["label"] = widget.result;
          return await foods.doc(widget.id).set(data).then((value) {
            return data;
          })
            .catchError((error) => print("Failed to add food: $error"));
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
                stream: FirebaseFirestore.instance.collection(widget.collectionName).doc(widget.id.toString()).snapshots(),
                builder: (context, foodSnapshot) {
                  if (foodSnapshot.hasData && foodSnapshot.data != null) {
                    DocumentSnapshot foodDoc = foodSnapshot.data;
                    Map<String,dynamic> foodData = foodDoc.data();
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          child : Padding(
                            padding: const EdgeInsets.only(top:8.0, bottom: 8),
                            child: FutureBuilder(
                              future: Future.value(widget.fetchedImages),
                              builder: (context, wikiImagesSnapshot){
                                if(wikiImagesSnapshot.connectionState == ConnectionState.done){
                                  List<ImageProvider> images = wikiImagesSnapshot.data;
                                  if(images != null){
                                    if(images.length>1){
                                        return CarouselSlider(
                                          items: images.map((e){
                                            return FadeInImage(
                                              image: e,
                                              placeholder: AssetImage("color_placeholder.png"),
                                              height: 200,
                                              width: 300,
                                              fit: BoxFit.cover,
                                            );
                                          }).toList(),
                                          options: CarouselOptions(
                                            autoPlay: true,
                                            height: 200,
                                            initialPage: 0
                                          ),
                                        );
                                    }
                                    if(images.length== 1){
                                        return FadeInImage(
                                          image: images[0],
                                          placeholder: AssetImage("color_placeholder.png"),
                                          height: 200,
                                          width: 300,
                                          fit: BoxFit.cover,
                                        );
                                    }

                                  }
                                  return Container();
                                }else{
                                  return Container( width : 200, height: 200,child: Center(child: CircularProgressIndicator(),));
                                }
                              },
                            ),
                          ),
                        ),
                        Column(
                            mainAxisAlignment:  MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              foodData["photoUrl"] != null ?
                              Image.network(foodData["photoUrl"]) :
                              Container(
                                child: Column(
                                  mainAxisAlignment:  MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    InkWell(
                                      onTap: (){uploadPic(context);},
                                      child: Container(
                                        child :Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment:  CrossAxisAlignment.center,
                                          children: <Widget>[
                                            Text("add a Picture for ${foodData["label"]}"),
                                            Icon(Icons.add_a_photo),
                                          ],
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black26
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              ListTile(
                                title: Text("${foodData["label"]} in your position ? "),
                                leading: Icon(Icons.not_listed_location),
                                onTap:  () {
                                  String googleUrl = 'https://www.google.com/maps/search/?api=1&query=${foodData["label"]}';
                                  _launchURL(googleUrl);
                                }),
                              ListTile(
                                  title:Text("Get recipes for ${foodData["label"]}"),
                                  leading: Icon(Icons.receipt),
                                  onTap:  () {
                                    String allrecipesUrl = 'https://www.allrecipes.com/search/?wt=${foodData["label"]}';
                                    _launchURL(allrecipesUrl);
                                  }),


                              Container()
                            ],
                          ),
                      ],
                    );
                  }else{
                    return  CircularProgressIndicator();
                  }
                }
              );
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }
}
