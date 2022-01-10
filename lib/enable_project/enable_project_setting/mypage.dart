import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login.dart';
import 'colors.dart';

class MyPage extends StatefulWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Primary,
              ),
              child: Text(''),
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: const Text('도움말'),
              onTap: () {
                signOut();
                Navigator.pushNamed(context, '/help');
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: const Text('로그아웃'),
              onTap: () {
                signOut();
                Navigator.pushNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        iconTheme: IconThemeData(color: OnBackground),
        leading: IconButton(
          icon: new Icon(Icons.arrow_back_ios_new_rounded),
          color: OnBackground,
          onPressed: () {
            Navigator.pushNamed(context, '/home');
          },
        ),
        title: const Text('마이페이지',
            style: TextStyle(
                color: OnBackground
            )
        ),
        /*actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.logout),
            color: OnBackground,
            onPressed: () {
              signOut();
              Navigator.pushNamed(context, '/login',);
            },
          ),
        ],*/
        backgroundColor: Bar,
        centerTitle: true,
      ),
      floatingActionButton: Column(
          //mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(height: 180),
            FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/edit',);
              },
              backgroundColor: Primary,
              child: const Icon(Icons.edit),
            ),
          ]
      ),
    );
  }

  Future signOut() async {
    final FirebaseAuth auth = await FirebaseAuth.instance;
    await auth.signOut();
    uid = "";
    uid_google = "";
    name_user = "";
    email_user = "";
    url_user = "";
  }
}
