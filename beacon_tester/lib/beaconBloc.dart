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

  final _UUIDTextFieldController = BehaviorSubject<String>();
  Stream<String> get uuid => _UUIDTextFieldController.stream;
  StreamSink<String> get changeUUIDAction => _UUIDTextFieldController.sink;

  //output
  final _authorizationStatusController = BehaviorSubject<bool>();
  Stream<bool> get authorizationStatus => _authorizationStatusController.stream;

  final _locationServiceEnabledController = BehaviorSubject<bool>();
  Stream<bool> get locationServiceEnabled => _locationServiceEnabledController.stream;

  final _bluetoothEnabledController = BehaviorSubject<bool>();
  Stream<bool> get bluetoothEnabled => _bluetoothEnabledController.stream;

//  final _UUIDController = BehaviorSubject<String>();
//  Stream<String> get uuid => _UUIDController.stream;

  final _beaconsController = BehaviorSubject<List<Beacon>>();
  Stream<List<Beacon>> get beacons => _beaconsController.stream;
  
  static final Map<String, dynamic> _items = <String, dynamic>{};
  
  final StreamController<BluetoothState> streamController = StreamController();
  StreamSubscription<BluetoothState> _streamBluetooth;
  StreamSubscription<RangingResult> _streamRanging;
  Map<Region, List<Beacon>> _regionBeacons = <Region, List<Beacon>>{};
  List<Beacon> _beacons = <Beacon>[];
  bool authorizationStatusOk = false;
  bool internalLocationServiceEnabled = false;
  bool internalBluetoothEnabled = false;
  String _proximityUUID = '';

  BeaconBloc() {
    WidgetsBinding.instance.addObserver(this);

    uuid.listen((text) async {
      print('text: ' + text);
      _proximityUUID = text;
      _beacons.clear();
      _regionBeacons = <Region, List<Beacon>>{};
      _beaconsController.sink.add(_beacons);
      if (_streamRanging != null) {
        _streamRanging.cancel();
        _streamRanging = null;
      }

      await checkAllRequirements();
      if (authorizationStatusOk && internalLocationServiceEnabled && internalBluetoothEnabled) {
        await initScanBeacon();
      }
    });
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
//        await initScanBeacon();
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

    print('uuid: ' + _proximityUUID);
    var regions = <Region>[
      Region(
        identifier: 'Cubeacon',
        proximityUUID: _proximityUUID,
      ),
    ];

    if (_streamRanging != null) {
      if (_streamRanging.isPaused) {
        _streamRanging.resume();
        return;
      }
    }

    print('start ranging');
    print(regions);
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