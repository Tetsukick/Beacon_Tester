import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';

import 'package:provider/provider.dart';

import 'beaconBloc.dart';

class BeaconSearchPage extends StatelessWidget {
  BeaconSearchPage();

  @override
  Widget build(BuildContext context) {
    final beaconBloc = Provider.of<BeaconBloc>(context);
    final textBox = TextBox();
    return new Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey[50],
          centerTitle: true,
          title: textBox,
          leading: IconButton(
            icon: Icon(Icons.search),
            color: Colors.grey,
            onPressed: () {
              beaconBloc.changeUUIDAction.add(_textBoxState._text);
            },
          ),
          actions: <Widget>[
            StreamBuilder<BluetoothState>(
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final state = snapshot.data;

                  if (state == BluetoothState.stateOn) {
                    return IconButton(
                      icon: Icon(Icons.bluetooth_connected),
                      onPressed: () {},
                      color: Colors.lightBlueAccent,
                    );
                  }

                  if (state == BluetoothState.stateOff) {
                    return IconButton(
                      icon: Icon(Icons.bluetooth),
                      onPressed: () async {
                        if (Platform.isAndroid) {
                          try {
                            await flutterBeacon.openBluetoothSettings;
                          } on PlatformException catch (e) {
                            print(e);
                          }
                        } else if (Platform.isIOS) {

                        }
                      },
                      color: Colors.red,
                    );
                  }

                  return IconButton(
                    icon: Icon(Icons.bluetooth_disabled),
                    onPressed: () {},
                    color: Colors.grey,
                  );
                }

                return SizedBox.shrink();
              },
              initialData: BluetoothState.stateUnknown,
            ),
          ],
        ),
      body: StreamBuilder(
          stream: beaconBloc.beacons,
          builder: (context, snapshot) {
            if (snapshot.data == null || snapshot.data.length == 0) {
              return Center(child: CircularProgressIndicator(),);
            } else {
              return ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, int index) {
                    var item = snapshot.data[index] as Beacon;
                    return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.black38),
                          ),
                        ),
                        child: ListTile(
                          title: Text(item.proximityUUID),
                          subtitle: new Row(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              Flexible(
                                  child: Text(
                                      'Major: ${item.major}\nMinor: ${item.minor}',
                                      style: TextStyle(fontSize: 13.0)),
                                  flex: 1,
                                  fit: FlexFit.tight),
                              Flexible(
                                  child: Text(
                                      'Accuracy: ${item.accuracy}m\nRSSI: ${item.rssi}',
                                      style: TextStyle(fontSize: 13.0)),
                                  flex: 2,
                                  fit: FlexFit.tight)
                            ],
                          ),
                        ));
                  });
            }
          },
      )
    );
  }
}

_TextBoxState _textBoxState = _TextBoxState();

class TextBox extends StatefulWidget {
  @override
  _TextBoxState createState() => _textBoxState;
}

class _TextBoxState extends State<TextBox> {
  String _text;
  TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = new TextEditingController(text: '5A5EA2C9-8E7A-435D-901F-FBD52767DD60'); // <- こんな感じ
  }

  void _handleText(String e) {
    setState(() {
      _text = e;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      color: Colors.white,
      child: TextField(
        controller: _textEditingController,
        decoration:
        InputDecoration(border: InputBorder.none, hintText: 'Search'),
        onChanged: _handleText,
      ),
    );
  }
}
