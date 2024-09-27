class LocationModel{
  String title;
  double lat;
  double lng;

  LocationModel({required this.title,required this.lat,required this.lng});

  factory LocationModel.fromJson(Map<String, dynamic> data) {
    return LocationModel(
        title: data['title'],
        lat: data['position']['lat'],
        lng: data['position']['lng'],
    );
  }
  static List<LocationModel> fromJsonToList(List<dynamic> list) {
    return list.map((c) => LocationModel.fromJson(c)).toList();
  }
}