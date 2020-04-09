import 'dart:io';

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';

class BeaconBloc with WidgetsBindingObserver {
  // input
  final _lifeCycleActionController = BehaviorSubject<bool>();
  Sink<void> get changeLifeCycleAction => _lifeCycleActionController.sink;

  //output
  final _authorizationStatusController = BehaviorSubject<bool>();
  Stream<bool> get authorizationStatus => _authorizationStatusController.stream;

  final _locationServiceEnabledController = BehaviorSubject<bool>();
  Stream<bool> get locationServiceEnabled => _locationServiceEnabledController.stream;

  final _bluetoothEnabledController = BehaviorSubject<bool>();
  Stream<bool> get bluetoothEnabled => _bluetoothEnabledController.stream;

  final _beaconsController = BehaviorSubject<List<Beacon>>();
  Stream<List<Beacon>> get beacons => _beaconsController.stream;
  
  static final Map<String, dynamic> _items = <String, dynamic>{};
  
  static final StreamController<BluetoothState> streamController = StreamController();
  static StreamSubscription<BluetoothState> _streamBluetooth;
  static StreamSubscription<RangingResult> _streamRanging;
  static final _regionBeacons = <Region, List<Beacon>>{};
  final _beacons = <Beacon>[];
  bool authorizationStatusOk = false;
  bool internalLocationServiceEnabled = false;
  bool internalBluetoothEnabled = false;

  BeaconBloc() {
    WidgetsBinding.instance.addObserver(this);

    listeningState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    print('AppLifecycleState = $state');
    if (state == AppLifecycleState.resumed) {
      if (_streamBluetooth != null && _streamBluetooth.isPaused) {
        _streamBluetooth.resume();
      }
      await checkAllRequirements();
      if (authorizationStatusOk && internalLocationServiceEnabled && internalBluetoothEnabled) {
        await initScanBeacon();
      } else {
        await pauseScanBeacon();
        await checkAllRequirements();
      }
    } else if (state == AppLifecycleState.paused) {
      _streamBluetooth.pause();
    }
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

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _lifeCycleActionController.close();
    _authorizationStatusController.close();
    _locationServiceEnabledController.close();
    _bluetoothEnabledController.close();
    _beaconsController.close();
  }

  initScanBeacon() async {
//    await flutterBeacon.initializeScanning;
    await checkAllRequirements();
    if (!authorizationStatusOk ||
        !internalLocationServiceEnabled ||
        !internalBluetoothEnabled) {
      print('RETURNED, authorizationStatusOk=$authorizationStatusOk, '
          'locationServiceEnabled=$internalLocationServiceEnabled, '
          'bluetoothEnabled=$internalBluetoothEnabled');
      return;
    }
    print('scan status is OK');

    final regions = <Region>[
      Region(
        identifier: 'Cubeacon',
        proximityUUID: '5A5EA2C9-8E7A-435D-901F-FBD52767DD60',
      ),
    ];

    if (_streamRanging != null) {
      if (_streamRanging.isPaused) {
        _streamRanging.resume();
        return;
      }
    }

    print('start ranging');
    _streamRanging =
        flutterBeacon.ranging(regions).listen((RangingResult result) {
          print(result);
          if (result != null) {
            _regionBeacons[result.region] = result.beacons;
            _beacons.clear();
            _regionBeacons.values.forEach((list) {
              print('beacons');
              print(list);
              _beacons.addAll(list);
            });
            _beacons.sort(_compareParameters);
            print(_beacons);

            _beaconsController.sink.add(_beacons);
          }
        });
  }

  pauseScanBeacon() async {
    _streamRanging?.pause();
    if (_beacons.isNotEmpty) {
      _beacons.clear();

      _beaconsController.sink.add(_beacons);
    }
  }

  checkAllRequirements() async {
    final bluetoothState = await flutterBeacon.bluetoothState;
    internalBluetoothEnabled = bluetoothState == BluetoothState.stateOn;
    final authorizationStatus = await flutterBeacon.authorizationStatus;
    authorizationStatusOk =
        authorizationStatus == AuthorizationStatus.allowed ||
            authorizationStatus == AuthorizationStatus.always;
    internalLocationServiceEnabled =
    await flutterBeacon.checkLocationServicesIfEnabled;

    _bluetoothEnabledController.sink.add(internalBluetoothEnabled);
    _authorizationStatusController.sink.add(authorizationStatusOk);
    _locationServiceEnabledController.sink.add(internalLocationServiceEnabled);
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
}