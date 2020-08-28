import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("What's Diner ?"),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height:  MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[

            Container(),
            Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height:  MediaQuery.of(context).size.height * 0.1,
              child: RaisedButton(
                onPressed: () {Navigator.of(context).pushNamed('/find');},
                color: Theme.of(context).primaryColor,
                textColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                child:  Text("Tell me what I whant", style: TextStyle(
                    fontSize: 20.0
                ),),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height:  MediaQuery.of(context).size.height * 0.1,
              child: RaisedButton(
                onPressed: () {Navigator.of(context).pushNamed('/list');},
                color: Theme.of(context).primaryColor,
                textColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                child:  Text("List all your food", style: TextStyle(
                    fontSize: 20.0
                ),),
              ),
            ),
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
            Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height:  MediaQuery.of(context).size.height * 0.1,
              child: RaisedButton(
                onPressed: () {Navigator.of(context).pushNamed('/photos');},
                color: Theme.of(context).primaryColor,
                textColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                child:  Text("Manage the food's picture", style: TextStyle(
                    fontSize: 20.0
                ),),
              ),
            ),
            Container()
          ],
        ),
      ),
    );
  }
}
