import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:whateat/FoodList.dart';
import 'package:whateat/Home.dart';
import 'package:whateat/ImageSelector.dart';
import 'package:whateat/ModelTree.dart';
import 'package:whateat/Suggestion.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whateat/ThemeNotifier.dart';
import 'package:whateat/Values/themes.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SharedPreferences.getInstance().then((prefs){
    var darkModeOn = prefs.getBool('darkMode') ?? false;
    runApp(
        ChangeNotifierProvider<ThemeNotifier>(
          create: (_) => ThemeNotifier(darkModeOn ? darkTheme : lightTheme),
          child: MyApp(),
    )
    );
  });


}

class MyApp extends StatelessWidget {

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      theme: themeNotifier.getTheme(),
      title: "What's Dinner?",
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