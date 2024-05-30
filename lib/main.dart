import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart';

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

  @override
  void initState() {
    super.initState();
    initializeSocket();
  }

  void initializeSocket() {
    socket = IO.io('http://192.168.18.7:3000/', <String, dynamic>{
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

  late Position _currentPosition;
  late StreamSubscription<Position> positionStream;

  void startUpdatingLocation() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      _currentPosition = position;
      log(_currentPosition.toString());
      updateLocation(_currentPosition.latitude, _currentPosition.longitude);
    });
  }

  void stopUpdatingLocation() {
    positionStream.cancel();
  }

  void updateLocation(double latitude, double longitude) {
    socket.emit('updateLocation',
        {'driverId': "1", 'latitude': latitude, 'longitude': longitude});
  }

  @override
  void dispose() {
    super.dispose();
    socket.dispose();
    positionStream.cancel();
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
