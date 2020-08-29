import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String background = "assets/background.png";



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(5.0),
          child: ClipOval(
            child: Image(
              image: AssetImage("assets/whateat.png"),
            ),
          ),
        ),
        title: Center(
          child: Text("What's for diner ?",style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25
          ),
          textAlign: TextAlign.center,),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            image: AssetImage("assets/background.png"),
            fit: BoxFit.cover
          )
        ),
        width: MediaQuery.of(context).size.width,
        height:  MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[

            Container(),
            Container(
              width: 300,
              height:  50,
              child: RaisedButton(
                onPressed: () {Navigator.of(context).pushNamed('/find');},
                color: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                child:  Text("Find a meal", style: TextStyle(
                    fontSize: 20.0
                ),),
              ),
            ),
            Container(
              width: 300,
              height:  50,
              child: RaisedButton(
                onPressed: () {Navigator.of(context).pushNamed('/list');},
                color: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                child:  Text("List all the meals", style: TextStyle(
                    fontSize: 20.0
                ),),
              ),
            ),
            /*
            Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height:  MediaQuery.of(context).size.height * 0.1,
              child: RaisedButton(
                onPressed: () {Navigator.of(context).pushNamed('/suggest');},
                color: Theme.of(context).primaryColor,
                textColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                child:  Text("suggest some Food", style: TextStyle(
                    fontSize: 20.0
                ),),
              ),
            ),
            */
            Container(
              width: 300,
              height:  50,
              child: RaisedButton(
                onPressed: () {Navigator.of(context).pushNamed('/photos');},
                color: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                child:  Text("Manage the food's picture", style: TextStyle(
                    fontSize: 20.0
                ),),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: <Widget>[

                    FloatingActionButton(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    Image.asset("assets/light.png", width: 45, height: 45,),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

}
