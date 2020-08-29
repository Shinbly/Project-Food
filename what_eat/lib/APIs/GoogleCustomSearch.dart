import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


import 'package:flutter/services.dart';

import '../CacheUtils.dart';

class GoogleCustomSearch {
  FutureOr<String> _api_Key;
  FutureOr<String> _searchEngineId;

  GoogleCustomSearch() {
    Future<Map<String,dynamic>> data = rootBundle.loadString("assets/google_search.json").then((String data) {
      Map<String, dynamic> jsonData = json.decode(data);
      return jsonData;
    });
    _api_Key = Future.value(data).then((jsonData) {
      return jsonData["api_key"];
    });
    _searchEngineId = Future.value(data).then((jsonData) {
      return jsonData["searchEngineId"];
    });
  }

  Future<List<dynamic>> searchImage(String query, {bool cached = true, int nb_images = 5, int offset}) async {
    if(offset > 90 ){
      offset = 90;
    }
    Map<String, dynamic> value;

    String key = await Future.value(_api_Key);
    String cx = await Future.value(_searchEngineId);
    Uri apiUri = new Uri.https("www.googleapis.com", "/customsearch/v1", {
      "key": key,
      "cx": cx,
      "q": query,
      "searchType": "image",
      "imgType": "photo",
      "imgColorType": "color",
      "num": nb_images.toString(),
      "start" : offset.toString(),
    });
    return  http.get(apiUri).then((searchResult) {
      value = jsonDecode(searchResult.body);


      List<dynamic> items = value["items"];
      if (items != null) {

        List<dynamic> images = items.map((dynamic item) {
          Map<String, String> image = {};
          image['full'] = item['link'];
          image['thumbnail'] = item['image']['thumbnailLink'];
          image['source'] = "google Image";
          return image;
        }).toList();

        return images;
      } else {
        print(value["error"]["message"]);
        print('items null');
        return null;
      }
    });
  }

	Future<Map<String,String>> getImage(String query, {bool cached}) async {
		return searchImage(query).then((list){
		  if(list != null && list.length >0) {
		    return list[0];
		  }
		  else{
		    return null;
		  }
		});
	}

}
