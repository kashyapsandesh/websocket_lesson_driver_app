import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: DriverLocationPage(),
    );
  }
}

class DriverLocationPage extends StatefulWidget {
  @override
  _DriverLocationPageState createState() => _DriverLocationPageState();
}

class _DriverLocationPageState extends State<DriverLocationPage> {
  late IO.Socket socket;
  bool isOnline = false;
  String driverId = '1'; // Replace with the actual driver ID
  double latitude = 0.0;
  double longitude = 0.0;
  late StreamSubscription<Position> positionStream;
  late StreamSubscription<AccelerometerEvent> accelerometerStream;
  late StreamSubscription<GyroscopeEvent> gyroscopeStream;

  @override
  void initState() {
    super.initState();
    initializeSocket();
    checkLocationPermission();
  }

  void initializeSocket() {
    socket = IO.io('http://192.168.18.125:3000/', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.on('connect', (_) {
      print('Connected to the server');
    });

    socket.on('disconnect', (_) {
      print('Disconnected from the server');
    });

    socket.on('locationUpdated', (data) {
      print('Driver location updated: $data');
      setState(() {
        latitude = data['latitude'];
        longitude = data['longitude'];
      });
    });
  }

  void checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print(
          'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }
  }

  void toggleOnlineStatus(bool status) {
    setState(() {
      isOnline = status;
    });

    if (isOnline) {
      startUpdatingLocation();
    } else {
      stopUpdatingLocation();
    }
  }

  void startUpdatingLocation() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });
      log(position.toString());
      updateLocation(position.latitude, position.longitude);
    });

    accelerometerStream =
        accelerometerEvents.listen((AccelerometerEvent event) {
      handleSensorUpdate();
    });

    gyroscopeStream = gyroscopeEvents.listen((GyroscopeEvent event) {
      handleSensorUpdate();
    });
  }

  void stopUpdatingLocation() {
    positionStream.cancel();
    accelerometerStream.cancel();
    gyroscopeStream.cancel();
  }

  void handleSensorUpdate() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    updateLocation(position.latitude, position.longitude);
  }

  void updateLocation(double latitude, double longitude) {
    socket.emit('updateLocation',
        {'driverId': driverId, 'latitude': latitude, 'longitude': longitude});
  }

  @override
  void dispose() {
    super.dispose();
    socket.dispose();
    positionStream.cancel();
    accelerometerStream.cancel();
    gyroscopeStream.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Driver Location Update'),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Online Status: ${isOnline ? 'Online' : 'Offline'}'),
            CupertinoSwitch(
              value: isOnline,
              onChanged: toggleOnlineStatus,
            ),
            SizedBox(height: 20),
            Text('Latitude: $latitude'),
            Text('Longitude: $longitude'),
          ],
        ),
      ),
    );
  }
}
