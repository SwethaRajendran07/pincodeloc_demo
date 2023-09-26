import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LocationApp(),
    );
  }
}

class LocationApp extends StatefulWidget {
  @override
  _LocationAppState createState() => _LocationAppState();
}

class _LocationAppState extends State<LocationApp> {
  TextEditingController pincodeController = TextEditingController();
  String locationInfo = 'Getting location...';
  String? _currentAddress;
  Position? _currentPosition;

  Future<void> getCurrentLocation() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark placemark = placemarks.first;
        setState(() {
          locationInfo =
              'Current Location: ${position.latitude}, ${position.longitude}\nCity: ${placemark.locality}, Country: ${placemark.country}';
        });
      } else {
        setState(() {
          locationInfo = 'Location not found';
        });
      }
    } catch (e) {
      setState(() {
        locationInfo = 'Location not available';
      });
    }
  }

  Future<void> getLocationByPincode() async {
    try {
      final String enteredPincode = pincodeController.text;

      // Simulated mapping of pincodes to coordinates (latitude and longitude)
      Map<String, Map<String, double>> pincodeToCoordinates = {
        '10001': {'latitude': 40.7128, 'longitude': -74.0060},
        '90210': {'latitude': 34.0696, 'longitude': -118.4052},
        // Add more pincode-coordinate pairs as needed
      };

      if (pincodeToCoordinates.containsKey(enteredPincode)) {
        final Map<String, double> coordinates = pincodeToCoordinates[enteredPincode]!;

        final List<Placemark> placemarks = await placemarkFromCoordinates(
          coordinates['latitude']!,
          coordinates['longitude']!,
        );

        if (placemarks.isNotEmpty) {
          final Placemark placemark = placemarks.first;
          setState(() {
            locationInfo = 'City: ${placemark.locality}, Country: ${placemark.country}';
          });
        } else {
          setState(() {
            locationInfo = 'Location not found';
          });
        }
      } else {
        setState(() {
          locationInfo = 'Location not found';
        });
      }
    } catch (e) {
      setState(() {
        locationInfo = 'Location not available';
      });
    }
  }

  ///

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((Position position) {
      setState(() => _currentPosition = position);
      _getAddressFromLatLng(_currentPosition!);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(_currentPosition!.latitude, _currentPosition!.longitude).then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress = '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location App'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: pincodeController,
              decoration: InputDecoration(labelText: 'Enter Pincode'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                getLocationByPincode();
              },
              child: Text('Get Location by Pincode'),
            ),
            SizedBox(height: 20),
            Text(
              locationInfo,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _getCurrentPosition();
              },
              child: Icon(Icons.location_on),
            ),
            SizedBox(height: 20),
            Text('LAT: ${_currentPosition?.latitude ?? ""}'),
            Text('LNG: ${_currentPosition?.longitude ?? ""}'),
            Text('ADDRESS: ${_currentAddress ?? ""}'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    pincodeController.dispose();
    super.dispose();
  }
}
