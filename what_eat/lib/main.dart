import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:whateat/FoodList.dart';
import 'package:whateat/Home.dart';
import 'package:whateat/ImageSelector.dart';
import 'package:whateat/ModelTree.dart';
import 'package:whateat/Suggestion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "What's Dinner?",
      theme: ThemeData(
        primarySwatch: Colors.red,
        primaryColor: Colors.red[700]
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        //visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => Home(),
        '/list': (context) => FoodList(),
        '/find': (context) => ModelTree(),
        '/suggest': (context) => Suggestion(),
        '/photos': (context) => ImageSelector(),
      },
    );
  }
}