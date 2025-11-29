// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'city.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

City _$CityFromJson(Map<String, dynamic> json) => City(
      id: json['id'] as String,
      name: json['name'] as String,
      canton: json['canton'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      population: (json['population'] as num).toInt(),
      areaSqKm: (json['area_sq_km'] as num).toDouble(),
      flagUrl: json['flag_url'] as String,
    );

Map<String, dynamic> _$CityToJson(City instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'canton': instance.canton,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'population': instance.population,
      'area_sq_km': instance.areaSqKm,
      'flag_url': instance.flagUrl,
    };
