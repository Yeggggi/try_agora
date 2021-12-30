import './pages/callpage.dart';
import './pages/homepage.dart';
import './pages/lobby.dart';
import './pages/loginpage.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
      routes: {
        CallPage.routeName: (context) => CallPage(username: '', channelName: '',),
        LobbyPage.routeName: (context) => LobbyPage(username: '',),
        LoginPage.routeName: (context) => LoginPage(),
      },
    );
  }
}
