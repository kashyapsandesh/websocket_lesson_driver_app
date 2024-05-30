class Driver {
  final int id;
  final double latitude;
  final double longitude;

  Driver({required this.id, required this.latitude, required this.longitude});

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['driverId'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}
