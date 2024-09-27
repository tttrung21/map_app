import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:map_app/model/LocationModel.dart';

class Repository {
  Future<List<LocationModel>> fetchLocations(String query) async {
    final apiKey = dotenv.env['API_KEY'];
    List<LocationModel> listLocation = [];
    if (query.isEmpty) {
      return listLocation;
    }

    final url = Uri.parse(
        'https://autosuggest.search.hereapi.com/v1/autosuggest?q=$query&apiKey=$apiKey&in=countryCode:VNM&at=21.0285,105.8542');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        String decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        listLocation = LocationModel.fromJsonToList(data['items']);
        print(data);
      } else {
        print('Error: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
    return listLocation;
  }
}
