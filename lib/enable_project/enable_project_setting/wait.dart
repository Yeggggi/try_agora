import 'package:flutter/material.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';


import 'chat.dart';
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
  /// create a channelController to retrieve text value
  final _channelController = TextEditingController();
  bool _isChannelCreated = true;
  /// if channel textField is validated to have error
  bool _validateError = false;

  String myChannel = '';

  ClientRole? _role = ClientRole.Broadcaster;

  final Map<String, List<String>> _seniorMember = {};

  // @override
  // void dispose() {
  //   // dispose input controller
  //   _channelController.dispose();
  //   super.dispose();
  // }


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
                  onPressed: onJoin,
                      // ()  async{
                    // Navigator.pushNamed(context, '/chat',);
                  // },
                  child: Text('준비'),
                )
              ],
            ),
          ],
        ),
        ]),
      );
  }
  Future<void> onJoin() async {
    // update input validation
    setState(() {
      _channelController.text.isEmpty
          ? _validateError = true
          : _validateError = false;
    });
    // if (_channelController.text.isNotEmpty) {
      // await for camera and mic permissions before pushing video page
      // await _handleCameraAndMic(Permission.camera);
      await _handleCameraAndMic(Permission.microphone);
      // push video page with given channel name
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            // channelName: _channelController.text,
            role: _role,
          ),
        ),
      );
    // }
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }
}