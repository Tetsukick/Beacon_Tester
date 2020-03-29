import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';

class BeaconStore {
  static final Map<String, dynamic> _items = <String, dynamic>{};
  static final BeaconStore _cache = BeaconStore._internal();
  
  static final StreamController<BluetoothState> streamController = StreamController();
  static StreamSubscription<BluetoothState> _streamBluetooth;
  static StreamSubscription<RangingResult> _streamRanging;
  static final _regionBeacons = <Region, List<Beacon>>{};
  static final _beacons = <Beacon>[];
  static bool authorizationStatusOk = false;
  static bool locationServiceEnabled = false;
  static bool bluetoothEnabled = false;

  BeaconStore._internal() {
    listeningState();
  }

  factory BeaconStore() {
    return _cache;
  }

  listeningState() async {
    print('Listening to bluetooth state');
    _streamBluetooth = flutterBeacon
        .bluetoothStateChanged()
        .listen((BluetoothState state) async {
      print('BluetoothState = $state');
      streamController.add(state);

      switch (state) {
        case BluetoothState.stateOn:
          initScanBeacon();
          break;
        case BluetoothState.stateOff:
          await pauseScanBeacon();
          await checkAllRequirements();
          break;
      }
    });
  }

  initScanBeacon() async {
    await flutterBeacon.initializeScanning;
    await checkAllRequirements();
    if (!authorizationStatusOk ||
        !locationServiceEnabled ||
        !bluetoothEnabled) {
      print('RETURNED, authorizationStatusOk=$authorizationStatusOk, '
          'locationServiceEnabled=$locationServiceEnabled, '
          'bluetoothEnabled=$bluetoothEnabled');
      return;
    }
    final regions = <Region>[
      Region(
        identifier: 'Cubeacon',
        proximityUUID: 'CB10023F-A318-3394-4199-A8730C7C1AEC',
      ),
    ];

    if (_streamRanging != null) {
      if (_streamRanging.isPaused) {
        _streamRanging.resume();
        return;
      }
    }

    _streamRanging =
        flutterBeacon.ranging(regions).listen((RangingResult result) {
          print(result);
          if (result != null) {
            _regionBeacons[result.region] = result.beacons;
            _beacons.clear();
            _regionBeacons.values.forEach((list) {
              _beacons.addAll(list);
            });
            _beacons.sort(_compareParameters);
            print(_beacons);
          }
        });
  }

  pauseScanBeacon() async {
    _streamRanging?.pause();
    if (_beacons.isNotEmpty) {
      _beacons.clear();
    }
  }

  checkAllRequirements() async {
    final bluetoothState = await flutterBeacon.bluetoothState;
    bluetoothEnabled = bluetoothState == BluetoothState.stateOn;
    final authorizationStatus = await flutterBeacon.authorizationStatus;
    authorizationStatusOk =
        authorizationStatus == AuthorizationStatus.allowed ||
            authorizationStatus == AuthorizationStatus.always;
    locationServiceEnabled =
    await flutterBeacon.checkLocationServicesIfEnabled;
  }

  int _compareParameters(Beacon a, Beacon b) {
    int compare = a.proximityUUID.compareTo(b.proximityUUID);

    if (compare == 0) {
      compare = a.major.compareTo(b.major);
    }

    if (compare == 0) {
      compare = a.minor.compareTo(b.minor);
    }

    return compare;
  }

  stream() {
    streamController.stream;
  }

  streamClose() {
    streamController.close();
  }

  cancel() {
    _streamRanging.cancel();
    _streamBluetooth.cancel();
  }

  pause() {
    _streamBluetooth.pause();
  }

  resume() {
    _streamBluetooth.resume();
  }

  getStreamBluetooth() => _streamBluetooth;
  getStreamRanging() => _streamRanging;
  getRegionBeacons() => _regionBeacons;
  getBeacons() => _beacons;
  getAuthorizationStatusOk() => authorizationStatusOk;
  getLocationServiceEnabled() => locationServiceEnabled;
  getBluetoothEnabled() => bluetoothEnabled;
}