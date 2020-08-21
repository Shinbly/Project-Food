import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;


import 'package:flutter/services.dart';

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

  Future<Map<String,dynamic>> searchImage(String query, int nbImages) async {
    String key = await Future.value(_api_Key);
    String cx = await Future.value(_searchEngineId);
    String formatedQuery = query.split(' ').join('%20');
    String apiUrl = "https://www.googleapis.com/customsearch/v1?key=${key}&cx=$cx&q=$query&searchType=image&num=$nbImages";

    return await http.get(apiUrl).then((rep) {
      return jsonDecode(rep.body);
    });
  }




}
