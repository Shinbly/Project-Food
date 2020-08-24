import 'dart:convert';

import 'package:whateat/CacheUtils.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Spoonacular {

  Spoonacular(){}

  static void searchFood(String query, {bool cached = true}) async {
    dynamic value;

    dynamic result = cached ? await getInCache(query, "spoonacular") : null;
    if (result != null) {
      value = jsonDecode(result);
    } else {
      Uri apiUri = new Uri.http(
          "spoonacular-recipe-food-nutrition-v1.p.rapidapi.com", "/recipes/search", {
        "query": query,
        "instructionsRequired": "true",
        "number": "5"
      });
      print("\n\n\n\n");
      print(apiUri.toString());
      print("\n\n\n\n");

      dynamic searchResult = (await http.get(apiUri, headers: {
      "x-rapidapi-host": "spoonacular-recipe-food-nutrition-v1.p.rapidapi.com",
      "x-rapidapi-key": "bc442a1109mshfe856c3abff50c2p108b56jsn5a87b232efa0",
      "useQueryString": "true"})).body;
      if(cached) {
        storeInCache(query, "spoonacular", searchResult);
      }
      value = jsonDecode(searchResult);
    }
    return value;
}
}