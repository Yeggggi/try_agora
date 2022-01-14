import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

import 'login.dart';
import 'colors.dart';
import 'settings.dart';
import 'user.dart';

bool isEdit = false;
TextEditingController _editingController =TextEditingController(text: initialText);
String initialText = "";

class ChatPage extends StatefulWidget {
  /// non-modifiable channel name of the page
  // final String? channelName;

  /// non-modifiable client role of the page
  final ClientRole? role;
  // final String? channelName;

  const ChatPage({Key? key, this.role}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

bool toggle = false;

class _ChatPageState extends State<ChatPage> {
  final _formKey = GlobalKey<FormState>(debugLabel: '_GuestBookState');
  final _controller = TextEditingController();
  Color _floatingbuttonColor = TextWeak;
  bool muted = false;
  late RtcEngine _engine;
  Map<int, Users_Isspeak> _userMap = new Map<int, Users_Isspeak>();
  int _remoteUid = 0;
  bool _joined = false;
  final _users = <int>[];
  final _infoStrings = <String>[];
  int? streamId;
  int? _localUid;
  //for token
  String baseUrl = ''; //Enter the link to your deployed token server over here
  int uid = 0;
  late String token;



  @override
  void dispose() {
    // clear users
    _users.clear();
    // destroy sdk
    _engine.leaveChannel();
    _engine.destroy();
    super.dispose();
  }

  // @override
  // void initState() {
  //   super.initState();
  //   initPlatformState().whenComplete((){
  //       setState(() {});
  //     });
  //   // initPlatformState();
  // }

  @override
  void initState() {
    super.initState();
    // initialize agora sdk
    initialize();
  }

  Future<void> initialize() async {
    if (APP_ID.isEmpty) {
      setState(() {
        _infoStrings.add(
          'APP_ID missing, please provide your APP_ID in settings.dart',
        );
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }
    // streamId = await _engine.createDataStream(true, true);
    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    // await getToken();
    await _engine.joinChannel(Token, channelName, null, 0);


    // await _initAgoraRtcEngine();
    // streamId = await _engine.createDataStream(true, true);
    // _addAgoraEventHandlers();
    // await _engine.enableWebSdkInteroperability(true);
    // VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    // //configuration.dimensions = VideoDimensions(1920, 1080);
    // await _engine.setVideoEncoderConfiguration(configuration);
    // await _engine.joinChannel(Token, channelName, null, 0);
  }

  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.create(APP_ID);
    await _engine.enableAudio();
    // await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    // await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfile.Communication);

    //만약에 1to1으로 만들려면 LiveBroadcasting이거 대신에 Communication으로 넣으면 일대일이 가능해짐
    // await _engine.setClientRole(ClientRole.Broadcaster);
    await _engine.enableAudioVolumeIndication(250, 3, true);

  }

  @override
  Widget build(BuildContext context) {

    String chats = "";
    String local_chats = "";
    final fb = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: new Icon(Icons.arrow_back_ios_new_rounded),
          color: OnBackground,
          onPressed: () {
            // _engine.sendStreamMessage(streamId!, "end");
            Navigator.of(context).pop();
            // Navigator.pushNamed(context, '/wait',);
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
      floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 200),
            FloatingActionButton(
              onPressed: _onToggleMute,
              backgroundColor: _floatingbuttonColor,
              child: Icon(
                muted ? Icons.mic : Icons.mic_none,
                color: toggle ? _floatingbuttonColor : Primary,
              ),

              // onPressed: () {
              //   setState(() {
              //     toggle = !toggle;
              //     if(_floatingbuttonColor == Secondary){
              //       _floatingbuttonColor = TextWeak;
              //     }
              //     else {
              //       _floatingbuttonColor = Secondary;
              //     }
              //     //backgroundColor = Background;
              //   });
              // },
            ),
          ]
      ),
      body: Column(children: <Widget>[
        const SizedBox(height: 10),
        //Image.asset('assets/chat.png'),
        _buildAvatar(),
        const SizedBox(height: 10),
        /*FloatingActionButton(
          onPressed: () {
            //mic on/off
          },
          backgroundColor: Secondary,
          child: const Icon(Icons.mic),
        ),*/
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: fb.collection("chats").snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              //   if (!(snapshot.hasError)) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text("Loading");
              }
              return ListView.builder(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemCount: snapshot.data?.docs.length,
                itemBuilder: (context, index) {
                  if ((snapshot.data?.docs[index]['userId'] == uid_google)) {
                    String chats = (snapshot.data?.docs[index]['text'])
                        .toString();
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // const SizedBox(height: 8),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: Row(children: [
                              Text((snapshot.data?.docs[index]['name'])
                                  .toString()),
                              const SizedBox(width: 8),
                              isEdit ? Expanded(
                                child: TextField(
                                    controller: TextEditingController(text: chats),
                                    onChanged: (newValue){
                                      local_chats = newValue;
                                    }
                                ),
                              )
                                  :Text(chats)
                            ]),
                          ),
                        ),
                        isEdit ?
                        Row(children: [
                          TextButton(
                            child: const Text('save'),
                            onPressed: () async {
                              await updateStatus(local_chats);
                              setState(() {
                                isEdit = !isEdit;
                              });
                              //_showMyDialog();
                            },
                          ),
                        ]) : Row(children: [
                          /*IconButton(
                              icon: const Icon(
                                Icons.create,
                                semanticLabel: 'edit',
                              ),
                              onPressed: () async {
                                setState(() {
                                  isEdit = !isEdit;
                                });
                                //_showMyDialog();
                              },
                            ),*/
                          /*IconButton(
                              icon: const Icon(
                                Icons.delete,
                                semanticLabel: 'delete',
                              ),
                              onPressed: () async {
                                _showMyDialog();
                              },
                            ),*/
                        ])
                      ],
                    );
                  } else {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // const SizedBox(height: 8),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
                            child: Row(children: [
                              Text((snapshot.data?.docs[index]['name'])
                                  .toString()),
                              const SizedBox(width: 8),
                              isEdit ? Text((snapshot.data?.docs[index]['text'])
                                  .toString()) : Text((snapshot.data?.docs[index]['text'])
                                  .toString())
                            ]),
                          ),
                        ),
                      ],
                    );
                  }
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(25.0),
          child: Form(
            key: _formKey,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      //filled: true,
                      fillColor: Colors.white,
                      hintText: '메세지를 입력하세요',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '메세지를 입력하세요';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: new Icon(Icons.arrow_upward),
                  color: Primary,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await addMessage(_controller.text);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Future addMessage(String text) async {
    await FirebaseFirestore.instance.collection("chats").add({
      "text": text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'name': FirebaseAuth.instance.currentUser!.displayName,
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'email': FirebaseAuth.instance.currentUser!.email,
    });
  }

  /*Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('메세지 삭제 알림'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Text('메세지를 정말 삭제 하시겠어요?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () async {
                //print('Confirmed');
                final QuerySnapshot result = await FirebaseFirestore.instance
                    .collection('chats')
                    .get();
                final List<DocumentSnapshot> documents = result.docs;
                String targetDoc = "";
                String creatorUID = "";
                documents.forEach((data) {
                  if (data['email'] == email_user) {
                    targetDoc = data.id;
                    creatorUID = data['userId'];
                  }
                });
                if (creatorUID == uid_google) {
                  var firebaseUser = FirebaseAuth.instance.currentUser;
                  FirebaseFirestore.instance
                      .collection("chats")
                      .doc(targetDoc)
                      .delete()
                      .then((data) {
                    //print("Deleted!");
                  });
                } else {
                  //print("not matching the user id");
                  //print(email_user);
                }
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }*/

  Future updateStatus(String text) async{
    final firestoreInstance = FirebaseFirestore.instance;
    final QuerySnapshot result =
    await firestoreInstance.collection('chats').get();
    final List<DocumentSnapshot> documents = result.docs;
    final User user_uid = FirebaseAuth.instance.currentUser!;
    String targetDoc = "";
    String creatorUID = "";
    documents.forEach((data) {if(data['userId'] == user_uid.uid) {targetDoc = data.id;}});
    //print(targetDoc);
    //print(user_uid.uid);
    var firebaseUser = FirebaseAuth.instance.currentUser;
    firestoreInstance
        .collection("chats")
        .doc(targetDoc)
        .update({"text": text}).then((_) {
      print("success!");
    });
    //is Speaking

    // Navigator.pop(context);
  }

  Widget _buildAvatar(){
    /*return GridView.builder(
      shrinkWrap: true,
      itemCount: _userMap.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: MediaQuery.of(context).size.height / 1100,
          crossAxisCount: 2),
      itemBuilder: (BuildContext context, int index) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          child: Container(
              color: Colors.white,
              child: (_userMap.entries.elementAt(index).key == _localUid)
                  ? RtcLocalView.SurfaceView()
                  : RtcRemoteView.SurfaceView(
                  uid: _userMap.entries.elementAt(index).key)),
          decoration: BoxDecoration(
            border: Border.all(
                color: _userMap.entries.elementAt(index).value.isSpeaking
                    ? Colors.blue
                    : Colors.grey,
                width: 6),
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
          ),
        ),
      ),
    );*/
    return GridView.builder(
      shrinkWrap: true,
      itemCount: _userMap.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: MediaQuery.of(context).size.height / 400,
          crossAxisCount: 2),
      itemBuilder: (BuildContext context, int index) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          child: Column(
            children: [
              Container(
              color: Colors.white,
            width: 70,
            child: PopupMenuButton(
                  icon: Container(
                    width: 33,
                    height: 58,
                    child: _userCircular(),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: _userMap.entries.elementAt(index).value.isSpeaking
                              ? Colors.blue
                              : Colors.grey,
                          width: 4.0),
                      borderRadius: BorderRadius.all(
                        Radius.circular(100.0),
                      ),
                    ),
                  ),
              itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String> (
                  value: '1',
                  child: Text('mypage'),
                ),
                PopupMenuItem<String> (
                  value: '2',
                  child: Text('history'),
                ),
              ];
            },
            ),
          // decoration: BoxDecoration(
          //   border: Border.all(
          //       color: _userMap.entries.elementAt(index).value.isSpeaking
          //           ? Colors.blue
          //           : Colors.grey,
          //       width: 6),
          //   borderRadius: BorderRadius.all(
          //     Radius.circular(10.0),
          //   ),
          // ),

        ),
              Text('$name_user'),
            ],),
      ),
      ),
    );

  }

  Widget _userCircular(){
    return CircleAvatar(
      backgroundImage: NetworkImage(
          "https://4.bp.blogspot.com/-Jx21kNqFSTU/UXemtqPhZCI/AAAAAAAAh74/BMGSzpU6F48/s1600/funny-cat-pictures-047-001.jpg"
      ),
      backgroundColor: Colors.red,
    );
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }



  /// Add agora event handlers
  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(
      error: (code) {
        setState(() {
          final info = 'onError: $code';
          _infoStrings.add(info);
        });
      },
      joinChannelSuccess: (channel, uid, elapsed) {
        setState(() {
          final info = 'onJoinChannel: $channel, uid: $uid';
          _infoStrings.add(info);
          _localUid = uid;
          _userMap.addAll({uid: Users_Isspeak(uid, false)});
        });
      },
      leaveChannel: (stats) {
        setState(() {
          _infoStrings.add('onLeaveChannel');
          _users.clear();
          _userMap.clear();
        });
      },
      userJoined: (uid, elapsed) {
        setState(() {
          final info = 'userJoined: $uid';
          _infoStrings.add(info);
          _users.add(uid);
          _userMap.addAll({uid: Users_Isspeak(uid, false)});
        });
      },
      userOffline: (uid, elapsed) {
        setState(() {
          final info = 'userOffline: $uid';
          _infoStrings.add(info);
          _users.remove(uid);
          _userMap.remove(uid);
        });
      },
      firstRemoteVideoFrame: (uid, width, height, elapsed) {
        setState(() {
          final info = 'firstRemoteVideo: $uid ${width}x $height';
          _infoStrings.add(info);
        });
      },
      // tokenPrivilegeWillExpire: (token) async {
      //   await getToken();
      //   await _engine.renewToken(token);
      // },
        /// Detecting active speaker by using audioVolumeIndication callback
        audioVolumeIndication: (volumeInfo, v) {
          volumeInfo.forEach((speaker) {
            //detecting speaking person whose volume more than 5
            if (speaker.volume > 5) {
              try {
                _userMap.forEach((key, value) {
                  //Highlighting local user
                  //In this callback, the local user is represented by an uid of 0.
                  if ((_localUid?.compareTo(key) == 0) && (speaker.uid == 0)) {
                    setState(() {
                      _userMap.update(key, (value) => Users_Isspeak(key, true));
                    });
                  }

                  //Highlighting remote user
                  else if (key.compareTo(speaker.uid) == 0) {
                    setState(() {
                      _userMap.update(key, (value) => Users_Isspeak(key, true));
                    });
                  } else {
                    setState(() {
                      _userMap.update(key, (value) => Users_Isspeak(key, false));
                    });
                  }
                });
              } catch (error) {
                print('Error:${error.toString()}');
              }
            }
          });
        },
        //final String coordinate = "$message";
        // late String first;
        // late String second;
        // late double d1;
        // late double d2;
        // if (coordinates.compareTo('erase') == 0) {
        //   setState(() {
        //     drawingPoints = [];
        //     drawingPoints.add(drawingPoints[-1]);
        //   });
        // } else {
        //   first = coordinates.substring(0, coordinates.indexOf(' '));
        //   second = coordinates.substring(
        //       coordinates.indexOf(' '), coordinates.indexOf('a'));
        //   d1 = double.parse(first);
        //   d2 = double.parse(second);
        //   change = Offset(d1 * MediaQuery.of(context).size.width,
        //       d2 * MediaQuery.of(context).size.height);
        //   setState(() {
        //     drawingPoints.add(
        //       DrawingPoint(
        //         change,
        //         Paint()
        //           ..color = selectedColor
        //           ..isAntiAlias = true
        //           ..strokeWidth = strokeWidth
        //           ..strokeCap = StrokeCap.round,
        //       ),
        //     );
        //   });
        // }

        // print(info);
        // _infoStrings.add(info);
      // },
      streamMessageError: (_, __, error, ___, ____) {
        final String info = "here is the error $error";
        print(info);
      },
    ));
  }


  /// Info panel to show logs
  Widget _panel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: ListView.builder(
            reverse: true,
            itemCount: _infoStrings.length,
            itemBuilder: (BuildContext context, int index) {
              if (_infoStrings.isEmpty) {
                return Text("null");  // return type can't be null, a widget was required
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.yellowAccent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _infoStrings[index],
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  //get token when it expire
  Future<void> getToken() async {
    final response = await http.get(
      Uri.parse(baseUrl +
          '/rtc/' +
          channelName +
          '/publisher/uid/' +
          uid.toString()
        // To add expiry time uncomment the below given line with the time in seconds
        // + '?expiry=45'
      ),
    );

    if (response.statusCode == 200) {
      setState(() {
        token = response.body;
        token = jsonDecode(token)['rtcToken'];
      });
    } else {
      print('Failed to fetch the token');
    }
  }
}