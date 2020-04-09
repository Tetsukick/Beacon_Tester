import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';

import 'beaconSearch.dart';
import 'beaconBloc.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MultiProvider(
          providers: [
            Provider<BeaconBloc>(
              create: (context) => BeaconBloc(),
              dispose: (context, bloc) => bloc.dispose(),
            ),
          ],
          child: MyHomePage(title: 'Flutter BLoC Sample'),
        )
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          bottom: TabBar(
            tabs: <Widget>[
              new Tab(
                icon: new Icon(Icons.network_check),
              ),
              new Tab(
                icon: new Icon(Icons.phonelink_ring),
              ),
              new Tab(
                icon: new Icon(Icons.settings),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget> [
            BeaconSearchPage(),
            new NewPage("send"),
            new NewPage("settings"),
          ],
        ),
        // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}

class NewPage extends StatelessWidget {
  final String title;
  NewPage(this.title);
  @override
  Widget build(BuildContext buildContext) {
    return new Scaffold(
      body: new Center(
        child: new Text(title),
      )
    );
  }
}