import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';

import 'beaconStore.dart';

class BeaconSearchPage extends StatelessWidget {
  final beaconStore = BeaconStore();
  BeaconSearchPage();

  @override
  Widget build(BuildContext buildContext) {
    return new Scaffold(
      body: beaconStore.getBeacons() == null || beaconStore.getBeacons().isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView(
        children: ListTile.divideTiles(
            context: buildContext,
            tiles: beaconStore.getBeacons().map((beacon) {
              return ListTile(
                title: Text(beacon.proximityUUID),
                subtitle: new Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Flexible(
                        child: Text(
                            'Major: ${beacon.major}\nMinor: ${beacon.minor}',
                            style: TextStyle(fontSize: 13.0)),
                        flex: 1,
                        fit: FlexFit.tight),
                    Flexible(
                        child: Text(
                            'Accuracy: ${beacon.accuracy}m\nRSSI: ${beacon.rssi}',
                            style: TextStyle(fontSize: 13.0)),
                        flex: 2,
                        fit: FlexFit.tight)
                  ],
                ),
              );
            })).toList(),
      ),
    );
  }
}
