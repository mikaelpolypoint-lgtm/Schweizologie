import 'package:json_annotation/json_annotation.dart';

part 'city.g.dart';

@JsonSerializable()
class City {
  final String id;
  final String name;
  final String canton;
  final double latitude;
  final double longitude;
  final int population;
  final String municipality;
  @JsonKey(name: 'postal_code')
  final String postalCode;
  @JsonKey(name: 'flag_url')
  final String flagUrl;

  City({
    required this.id,
    required this.name,
    required this.canton,
    required this.latitude,
    required this.longitude,
    this.population = 0,
    this.municipality = '',
    this.postalCode = '',
    this.flagUrl = '',
  });

  factory City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);
  Map<String, dynamic> toJson() => _$CityToJson(this);
}
