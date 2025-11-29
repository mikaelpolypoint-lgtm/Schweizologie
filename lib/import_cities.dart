import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'models/city.dart';

// 1. Helper to load and parse cities from CSV asset
Future<List<City>> loadCitiesFromAssets() async {
  print("Loading cities from CSV asset...");
  try {
    // Try loading as UTF-8, fallback to Latin-1
    String csvContent;
    try {
      csvContent = await rootBundle.loadString('assets/cities.csv');
    } catch (e) {
      print("UTF-8 load failed, trying to decode bytes directly...");
      final byteData = await rootBundle.load('assets/cities.csv');
      csvContent = latin1.decode(byteData.buffer.asUint8List());
    }

    final lines = const LineSplitter().convert(csvContent);
    final List<City> cities = [];

    // Skip header row (i=1)
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;

      final parts = line.split(','); 
      if (parts.length < 6) continue;

      try {
        final name = parts[0].trim();
        final canton = parts[1].trim();
        final lat = double.tryParse(parts[2].trim()) ?? 0.0;
        final lng = double.tryParse(parts[3].trim()) ?? 0.0;
        final pop = int.tryParse(parts[4].trim()) ?? 0;
        final area = double.tryParse(parts[5].trim()) ?? 0.0;
        final flag = parts.length > 6 ? parts[6].trim() : '';

        // Create City object (ID is temporary/random for local use)
        cities.add(City(
          id: 'csv_$i', 
          name: name,
          canton: canton,
          latitude: lat,
          longitude: lng,
          population: pop,
          areaSqKm: area,
          flagUrl: flag,
        ));
      } catch (e) {
        print("Error parsing line $i: $e");
      }
    }
    print("Parsed ${cities.length} cities from CSV.");
    return cities;
  } catch (e) {
    print("Error loading cities from assets: $e");
    return [];
  }
}

// 2. Function to upload to Firestore (optional now, but kept for admin/dev)
Future<void> importCitiesFromAssets() async {
  print("Starting upload to Firestore...");
  final cities = await loadCitiesFromAssets();
  if (cities.isEmpty) return;

  final firestore = FirebaseFirestore.instance;
  var batch = firestore.batch();
  int batchCount = 0;

  for (final city in cities) {
    final docRef = firestore.collection('cities').doc(); 
    batch.set(docRef, city.toJson());
    
    batchCount++;
    if (batchCount >= 400) {
      await batch.commit();
      print("Committed batch of $batchCount...");
      batch = firestore.batch();
      batchCount = 0;
    }
  }

  if (batchCount > 0) {
    await batch.commit();
  }
  print("Upload finished.");
}
