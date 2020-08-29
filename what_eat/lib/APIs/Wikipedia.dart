import 'dart:convert';

import 'package:http/http.dart' as http;

class Wiki{
  static Future<List<Map<String,dynamic>>> searchImages(String query) async {
    Uri apiUri = new Uri.https("en.wikipedia.org", "/w/api.php", {
      "action": "query",
      "titles": query,
      "prop" : "images",
      "format"  : "json"
    });
    return await http.get(apiUri).then((rep) {
      List imageList = [];
      Map<String, dynamic> jsonData = jsonDecode(rep.body);
      List<dynamic> images = jsonData["query"]["pages"][jsonData["query"]["pages"].keys.first]["images"];
      List<Future<String>> urls;
      print(jsonData);
      if(images != null && images.length> 0){
        urls = images.map((image) async {
          String title = image["title"];
          if (!title.contains('.svg')) {
            Uri mediaUri = new Uri.https("en.wikipedia.org", "/w/api.php", {
              "action": "query",
              "titles": title,
              "prop" : "imageinfo",
              "iiprop" : "url",
              "format"  : "json"
            });
            dynamic mediaRep = await http.get(mediaUri);
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
          return urls.map((e) => {"full" : e, "thumbnail" : null, "source" : "wikipedia"}).toList();
        });
      }else{
        print("wikipedia not found");
        return [];
      }
    });
  }
}