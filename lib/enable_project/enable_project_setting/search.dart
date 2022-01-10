import 'package:custom_radio_grouped_button/custom_radio_grouped_button.dart';
import 'package:flutter/material.dart';

import 'colors.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _formKey = GlobalKey<FormState>(debugLabel: '_GuestBookState');
  final _maxnumcontroller = TextEditingController();
  final int _maxnum = 2;
  final int _maxsec = 60;
  late int _category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: new Icon(Icons.arrow_back_ios_new_rounded),
          color: OnBackground,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('방 검색',
            style: TextStyle(
                color: OnBackground
            )
        ),
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.search),
            color: OnBackground,
            onPressed: () {
              Navigator.pushNamed(context, '/searchword',);
            },
          ),
        ],
        backgroundColor: Bar,
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CustomRadioButton(
                      buttonLables: [
                        "상담",
                        "면접",
                        "토론",
                        "스터디",
                        "만남",
                        "수다",
                      ],
                      buttonValues: [
                        0,
                        1,
                        2,
                        3,
                        4,
                        5,
                      ],
                      defaultSelected: 0,
                      //radioButtonValue: (value) => print(value),
                      radioButtonValue: (value) {
                        setState(() {
                          _category = value as int;
                        });
                        //print(_category);
                      },

                      //_selectedbutton = value.checked,
                      unSelectedColor: Theme.of(context).canvasColor,
                      selectedColor: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _maxnumcontroller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '방 최대인원 (2-4(명))',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || int.parse(value) < 2 || int.parse(value) > 4) {
                          return '2-4 사이의 숫자를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
