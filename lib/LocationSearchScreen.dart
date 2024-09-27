import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_app/model/LocationModel.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Repository/Repository.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  LocationSearchScreenState createState() => LocationSearchScreenState();
}

class LocationSearchScreenState extends State<LocationSearchScreen> {
  Timer? _debounce;
  List<LocationModel> _locations = [];
  bool _isLoading = false;
  TextEditingController searchTEC = TextEditingController();


  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () async{
      setState(() {
        _isLoading = true;
      });
      _locations = await Repository().fetchLocations(query);
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Search Locations'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search Box
              TextField(
                controller: searchTEC,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search for a location...',
                  prefixIcon: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: CircularProgressIndicator(),
                        )
                      : const Icon(Icons.search),
                  suffixIcon: searchTEC.text == '' ? null : GestureDetector(
                    onTap: () {
                      searchTEC.clear();
                      setState(() {
                        _locations = [];
                      });
                    },
                    child: const Icon(Icons.clear),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _locations.length,
                  itemBuilder: (context, index) {
                    final location = _locations[index];
                    return LocationItem(location: location, query: searchTEC.text);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LocationItem extends StatelessWidget {
  const LocationItem({super.key, required this.location, required this.query});

  final LocationModel location;
  final String query;

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(text, style: const TextStyle(fontSize: 16));
    }

    final matchIndex = text.indexOf(query);
    if (matchIndex == -1) {
      return Text(
        text,
        style: const TextStyle(fontSize: 16),
      );
    }

    final beforeMatch = text.substring(0, matchIndex);
    final matchText = text.substring(matchIndex, matchIndex + query.length);
    final afterMatch = text.substring(matchIndex + query.length);

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 16), // Default text style
        children: [
          TextSpan(text: beforeMatch),
          TextSpan(
            text: matchText,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold), // Highlight style
          ),
          TextSpan(text: afterMatch),
        ],
      ),
    );
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _openMaps(double targetLat, double targetLng) async {
    Position currentPosition = await _getCurrentLocation();
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${currentPosition.latitude},${currentPosition.longitude}&destination=$targetLat,$targetLng&travelmode=driving',
    );
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: const Icon(Icons.location_on_outlined),
      title: _buildHighlightedText(location.title, query),
      trailing: InkWell(onTap: () => _openMaps(location.lat, location.lng), child: const Icon(Icons.directions)),
    );
  }
}
