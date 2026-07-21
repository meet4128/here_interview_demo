import 'package:equatable/equatable.dart';

class PlaceResult extends Equatable {
  final String id;
  final String title;
  final String addressText;
  final double? latitude;
  final double? longitude;

  const PlaceResult({
    required this.id,
    required this.title,
    required this.addressText,
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  @override
  List<Object?> get props => [id, title, addressText, latitude, longitude];
}