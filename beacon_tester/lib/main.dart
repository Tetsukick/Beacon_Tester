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

//class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
//  TabController tabController;
//  final beaconStore = BeaconBloc();
//
//  @override
//  void didChangeAppLifecycleState(AppLifecycleState state) async {
//    print('AppLifecycleState = $state');
//    if (state == AppLifecycleState.resumed) {
//      if (beaconStore.getStreamBluetooth() != null && beaconStore.getStreamBluetooth().isPaused) {
//        beaconStore.resume();
//      }
//      await beaconStore.checkAllRequirements();
//      if (beaconStore.getAuthorizationStatusOk() && beaconStore.getLocationServiceEnabled() && beaconStore.getBluetoothEnabled()) {
//        await beaconStore.initScanBeacon();
//      } else {
//        await beaconStore.pauseScanBeacon();
//        await beaconStore.checkAllRequirements();
//      }
//    } else if (state == AppLifecycleState.paused) {
//      beaconStore.pause();
//    }
//  }
//
//  @override
//  void dispose() {
//    beaconStore.streamClose();
//    beaconStore.cancel();
//    flutterBeacon.close;
//    tabController.dispose();
//
//    super.dispose();
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      theme: ThemeData(
//        brightness: Brightness.light,
//        primaryColor: Colors.white,
//      ),
//      darkTheme: ThemeData(
//        brightness: Brightness.dark,
//      ),
//      home: Scaffold(
//        appBar: AppBar(
//          title: const Text('Beacon Checker'),
//          centerTitle: true,
//          actions: <Widget>[
//            if (!beaconStore.getAuthorizationStatusOk())
//              IconButton(
//                  icon: Icon(Icons.portable_wifi_off),
//                  color: Colors.red,
//                  onPressed: () async {
//                    await flutterBeacon.requestAuthorization;
//                  }),
//            if (!beaconStore.getLocationServiceEnabled())
//              IconButton(
//                  icon: Icon(Icons.location_off),
//                  color: Colors.red,
//                  onPressed: () async {
//                    if (Platform.isAndroid) {
//                      await flutterBeacon.openLocationSettings;
//                    } else if (Platform.isIOS) {
//
//                    }
//                  }),
//            StreamBuilder<BluetoothState>(
//              builder: (context, snapshot) {
//                if (snapshot.hasData) {
//                  final state = snapshot.data;
//
//                  if (state == BluetoothState.stateOn) {
//                    return IconButton(
//                      icon: Icon(Icons.bluetooth_connected),
//                      onPressed: () {},
//                      color: Colors.lightBlueAccent,
//                    );
//                  }
//
//                  if (state == BluetoothState.stateOff) {
//                    return IconButton(
//                      icon: Icon(Icons.bluetooth),
//                      onPressed: () async {
//                        if (Platform.isAndroid) {
//                          try {
//                            await flutterBeacon.openBluetoothSettings;
//                          } on PlatformException catch (e) {
//                            print(e);
//                          }
//                        } else if (Platform.isIOS) {
//
//                        }
//                      },
//                      color: Colors.red,
//                    );
//                  }
//
//                  return IconButton(
//                    icon: Icon(Icons.bluetooth_disabled),
//                    onPressed: () {},
//                    color: Colors.grey,
//                  );
//                }
//
//                return SizedBox.shrink();
//              },
//              stream: beaconStore.stream(),
//              initialData: BluetoothState.stateUnknown,
//            ),
//          ],
//          bottom: TabBar(
//            controller: tabController,
//            tabs: <Widget>[
//              new Tab(
//                icon: new Icon(Icons.network_check),
//              ),
//              new Tab(
//                icon: new Icon(Icons.phonelink_ring),
//              ),
//              new Tab(
//                icon: new Icon(Icons.settings),
//              ),
//            ],
//          ),
//        ),
//        body: new TabBarView(
//            children: <Widget>[new BeaconSearchPage(), new NewPage("send"), new NewPage("settings")],
//            controller: tabController,
//        )
//      ),
//    );
//  }
//}
