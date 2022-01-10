import 'package:flutter/material.dart';

import 'colors.dart';

bool isEdit = false;
String initialText = "";

class WaitPage extends StatefulWidget {
  const WaitPage({Key? key}) : super(key: key);

  @override
  _WaitPageState createState() => _WaitPageState();
}

bool toggle = false;

class _WaitPageState extends State<WaitPage> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: new Icon(Icons.arrow_back_ios_new_rounded),
          color: OnBackground,
          onPressed: () {
            Navigator.pushNamed(context, '/home',);
          },
        ),
        title: const Text('대화방',
            style: TextStyle(
                color: OnBackground
            )
        ),
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.settings),
            color: OnBackground,
            onPressed: () {
              Navigator.pushNamed(context, '/settingroom',);
            },
          ),
        ],
        backgroundColor: Bar,
        centerTitle: true,
      ),
      //backgroundColor: ChatBackground,
      backgroundColor: Background,
      body: Column(children: <Widget>[
        const SizedBox(height: 100),
        //Image.asset('assets/wait.png'),
        const SizedBox(height: 10),
        Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Secondary, // background
                    onPrimary: Colors.white, // foreground
                  ),
                  onPressed: ()  async{
                    Navigator.pushNamed(context, '/chat',);
                  },
                  child: Text('준비'),
                )
              ],
            ),
          ],
        ),
        ]),
      );
  }
}