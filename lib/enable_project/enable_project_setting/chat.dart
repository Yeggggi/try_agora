import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:permission_handler/permission_handler.dart';

import 'login.dart';
import 'colors.dart';
import 'settings.dart';

bool isEdit = false;
TextEditingController _editingController =TextEditingController(text: initialText);
String initialText = "";

class ChatPage extends StatefulWidget {
  /// non-modifiable channel name of the page
  // final String? channelName;

  /// non-modifiable client role of the page
  final ClientRole? role;

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
  int _remoteUid = 0;
  bool _joined = false;
  final _users = <int>[];
  final _infoStrings = <String>[];
  int? streamId;

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


    await _initAgoraRtcEngine();
    streamId = await _engine.createDataStream(true, true);
    _addAgoraEventHandlers();
    await _engine.enableWebSdkInteroperability(true);
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    //configuration.dimensions = VideoDimensions(1920, 1080);
    await _engine.setVideoEncoderConfiguration(configuration);
    // await _engine.joinChannel(null, channelName, null, 0);
  }

  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.create(APP_ID);
    await _engine.enableAudio();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    //만약에 1to1으로 만들려면 LiveBroadcasting이거 대신에 Communication으로 넣으면 일대일이 가능해짐
    await _engine.setClientRole(ClientRole.Broadcaster);
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
              backgroundColor: _floatingbuttonColor,
              child: Icon(
                  Icons.mic
                //toggle ? Icons.mic : Icons.mic_none,
                //color: toggle ? _floatingbuttonColor : Primary,
              ),
              onPressed: _onToggleMute,
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
    // Navigator.pop(context);
  }

  Widget _buildAvatar(){

    return Container(
      width: 58,
      child: PopupMenuButton(
        icon: CircleAvatar(
          backgroundImage: NetworkImage(
              "https://4.bp.blogspot.com/-Jx21kNqFSTU/UXemtqPhZCI/AAAAAAAAh74/BMGSzpU6F48/s1600/funny-cat-pictures-047-001.jpg"
          ),
          backgroundColor: Colors.red,
        ),
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem<String> (
              value: '1',
              child: Text('1'),
            ),
            PopupMenuItem<String> (
              value: '2',
              child: Text('2'),
            ),
          ];
        },
      ),
    );
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
      if(_floatingbuttonColor == Secondary){
        _floatingbuttonColor = TextWeak;
      }
      else {
        _floatingbuttonColor = Secondary;
      }
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
        });
      },
      leaveChannel: (stats) {
        setState(() {
          _infoStrings.add('onLeaveChannel');
          _users.clear();
        });
      },
      userJoined: (uid, elapsed) {
        setState(() {
          final info = 'userJoined: $uid';
          _infoStrings.add(info);
          _users.add(uid);
        });
      },
      userOffline: (uid, elapsed) {
        setState(() {
          final info = 'userOffline: $uid';
          _infoStrings.add(info);
          _users.remove(uid);
        });
      },
      firstRemoteVideoFrame: (uid, width, height, elapsed) {
        setState(() {
          final info = 'firstRemoteVideo: $uid ${width}x $height';
          _infoStrings.add(info);
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

}