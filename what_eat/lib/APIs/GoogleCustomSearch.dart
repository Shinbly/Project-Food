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

  Future<List<Map<String,ImageProvider>>> searchImage(String query, {bool cached = true}) async {
    dynamic result = cached ? await getInCache(query, "gcs") : null;
    dynamic value;
    if (result != null) {
      value = jsonDecode(result);
    } else {
      String key = await Future.value(_api_Key);
      String cx = await Future.value(_searchEngineId);
      Uri apiUri = new Uri.https("www.googleapis.com", "/customsearch/v1", {
        "key": key,
        "cx": cx,
        "q": query,
        "searchType": "image",
        "imgType": "photo",
        "imgColorType": "color",
        "num": "5",
      });
      dynamic searchResult = (await http.get(apiUri)).body;
      value = jsonDecode(searchResult);
      if (cached) {
        storeInCache(query, "gcs", searchResult);
      }
    }
    List<dynamic> items = value["items"];
    List<Map<String, ImageProvider>> images = items.map((item) {
      Map<String, ImageProvider> image =
      {
        "full": NetworkImage(item["link"]),
        "thumbnail": NetworkImage(item["image"]["thumbnailLink"])
      };
      return image;
    }).toList();
    return images;
  }

	Future<Map<String,ImageProvider>> getImage(String query, {bool cached}) async {
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
