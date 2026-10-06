import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'active_ride_screen.dart';
import 'scheduled_ride_screen.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  bool isRideNow = true;

  bool isDetectingLocation = false;
  bool locationDetected = false;

  bool isPickupConfirmed = false;
  bool isUpdatingAddress = false;

  bool isSearchingDestination = false;
  bool destinationSelected = false;
  bool isUpdatingDestinationAddress = false;

  bool isCalculatingRoute = false;
  bool routeCalculated = false;

  String pickupLocation = '';
  String destinationLocation = '';

  double? roadDistanceKm;
  double? roadDurationMinutes;

  Position? currentPosition;

  LatLng? selectedPickupPoint;
  LatLng? selectedDestinationPoint;

  List<LatLng> routePoints = [];

  final TextEditingController destinationController =
      TextEditingController();

  final MapController mapController = MapController();

  int selectedSeats = 1;

  // ============================================================
  // SCHEDULE
  // ============================================================

  DateTime? selectedScheduleDate;
  TimeOfDay? selectedScheduleTime;

  Timer? _addressUpdateTimer;
  Timer? _destinationSearchTimer;
  Timer? _routeUpdateTimer;

  List<DestinationResult> destinationSuggestions = [];

  @override
  void initState() {
    super.initState();

    detectCurrentLocation();
  }

  @override
  void dispose() {
    _addressUpdateTimer?.cancel();
    _destinationSearchTimer?.cancel();
    _routeUpdateTimer?.cancel();

    destinationController.dispose();
    mapController.dispose();

    super.dispose();
  }

  // ============================================================
  // CURRENT GPS LOCATION
  // ============================================================

  Future<void> detectCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      isDetectingLocation = true;
      locationDetected = false;
      isPickupConfirmed = false;

      pickupLocation = '';

      selectedPickupPoint = null;
      selectedDestinationPoint = null;

      destinationSelected = false;

      routeCalculated = false;
      routePoints = [];
      roadDistanceKm = null;
      roadDurationMinutes = null;
    });

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          isDetectingLocation = false;
        });

        await showLocationDialog(
          'Location is turned off',
          'Please turn ON Location/GPS on your phone and try again.',
        );

        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        setState(() {
          isDetectingLocation = false;
        });

        await showLocationDialog(
          'Location permission denied',
          'We need your location to automatically detect your starting point.',
        );

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          isDetectingLocation = false;
        });

        await showLocationDialog(
          'Location permission required',
          'Location permission was permanently denied. Please enable it from your phone settings.',
          showSettingsButton: true,
        );

        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      debugPrint(
        'GPS Latitude: ${position.latitude}',
      );

      debugPrint(
        'GPS Longitude: ${position.longitude}',
      );

      debugPrint(
        'GPS Accuracy: ${position.accuracy} meters',
      );

      final LatLng gpsPoint = LatLng(
        position.latitude,
        position.longitude,
      );

      final String address =
          await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        currentPosition = position;
        selectedPickupPoint = gpsPoint;
        pickupLocation = address;

        locationDetected = true;
        isDetectingLocation = false;

        isPickupConfirmed = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            selectedPickupPoint == null) {
          return;
        }

        try {
          mapController.move(
            selectedPickupPoint!,
            17,
          );
        } catch (e) {
          debugPrint(
            'Map move error: $e',
          );
        }
      });
    } catch (e) {
      debugPrint(
        'Location error: $e',
      );

      if (!mounted) return;

      setState(() {
        isDetectingLocation = false;
      });

      await showLocationDialog(
        'Unable to detect location',
        'Something went wrong while detecting your current location. Please try again.',
      );
    }
  }

  // ============================================================
  // REVERSE GEOCODING
  // ============================================================

  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final List<Placemark> placemarks =
          await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place =
            placemarks.first;

        final List<String> parts = [];

        if (place.name != null &&
            place.name!.trim().isNotEmpty) {
          parts.add(
            place.name!.trim(),
          );
        }

        if (place.street != null &&
            place.street!.trim().isNotEmpty &&
            place.street!.trim() !=
                place.name?.trim()) {
          parts.add(
            place.street!.trim(),
          );
        }

        if (place.subLocality != null &&
            place.subLocality!.trim().isNotEmpty) {
          parts.add(
            place.subLocality!.trim(),
          );
        }

        if (place.locality != null &&
            place.locality!.trim().isNotEmpty) {
          parts.add(
            place.locality!.trim(),
          );
        }

        if (place.postalCode != null &&
            place.postalCode!.trim().isNotEmpty) {
          parts.add(
            place.postalCode!.trim(),
          );
        }

        if (parts.isNotEmpty) {
          return parts.join(', ');
        }

        return 'Selected Location';
      }

      return 'Selected Location';
    } catch (e) {
      debugPrint(
        'Geocoding error: $e',
      );

      return 'Selected Location';
    }
  }

  // ============================================================
  // MAP MOVED
  // ============================================================

  void onMapPositionChanged(
    MapCamera camera,
  ) {
    if (!locationDetected) return;

    final LatLng newPoint =
        camera.center;

    // ----------------------------------------------------------
    // BEFORE STARTING POINT CONFIRMATION
    // ----------------------------------------------------------

    if (!isPickupConfirmed) {
      setState(() {
        selectedPickupPoint = newPoint;

        isUpdatingAddress = true;

        routeCalculated = false;
        routePoints = [];
        roadDistanceKm = null;
        roadDurationMinutes = null;
      });

      _addressUpdateTimer?.cancel();

      _addressUpdateTimer = Timer(
        const Duration(milliseconds: 600),
        () async {
          final String address =
              await getAddressFromCoordinates(
            newPoint.latitude,
            newPoint.longitude,
          );

          if (!mounted) return;

          setState(() {
            pickupLocation = address;
            isUpdatingAddress = false;
          });
        },
      );

      return;
    }

    // ----------------------------------------------------------
    // AFTER STARTING POINT CONFIRMATION
    // DESTINATION CAN BE MOVED
    // ----------------------------------------------------------

    if (isPickupConfirmed &&
        selectedDestinationPoint != null) {
      setState(() {
        selectedDestinationPoint =
            newPoint;

        destinationSelected = true;

        isUpdatingDestinationAddress =
            true;

        routeCalculated = false;
        routePoints = [];

        roadDistanceKm = null;
        roadDurationMinutes = null;
      });

      _routeUpdateTimer?.cancel();

      _routeUpdateTimer = Timer(
        const Duration(milliseconds: 700),
        () async {
          final String address =
              await getAddressFromCoordinates(
            newPoint.latitude,
            newPoint.longitude,
          );

          if (!mounted) return;

          setState(() {
            destinationLocation =
                address;

            destinationController.text =
                address;

            destinationController.selection =
                TextSelection.fromPosition(
              TextPosition(
                offset:
                    destinationController
                        .text
                        .length,
              ),
            );

            isUpdatingDestinationAddress =
                false;
          });

          await calculateRoadRoute();
        },
      );
    }
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  void moveToCurrentLocation() {
    if (currentPosition == null) {
      detectCurrentLocation();
      return;
    }

    if (isPickupConfirmed) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Starting point is already locked.',
          ),
        ),
      );

      return;
    }

    final LatLng gpsPoint = LatLng(
      currentPosition!.latitude,
      currentPosition!.longitude,
    );

    setState(() {
      selectedPickupPoint = gpsPoint;
      isPickupConfirmed = false;

      routeCalculated = false;
      routePoints = [];

      roadDistanceKm = null;
      roadDurationMinutes = null;
    });

    mapController.move(
      gpsPoint,
      17,
    );

    updateAddressAfterMoving(
      gpsPoint,
    );
  }

  Future<void> updateAddressAfterMoving(
    LatLng point,
  ) async {
    setState(() {
      isUpdatingAddress = true;
    });

    final String address =
        await getAddressFromCoordinates(
      point.latitude,
      point.longitude,
    );

    if (!mounted) return;

    setState(() {
      pickupLocation = address;
      isUpdatingAddress = false;
    });
  }

  // ============================================================
  // CONFIRM STARTING POINT
  // ============================================================

  Future<void> confirmPickupLocation() async {
    if (selectedPickupPoint == null) {
      return;
    }

    setState(() {
      isPickupConfirmed = true;
    });

    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Starting point locked.',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // DESTINATION SEARCH
  // ============================================================

  void onDestinationChanged(
    String value,
  ) {
    _destinationSearchTimer?.cancel();

    setState(() {
      destinationSelected = false;
      destinationLocation = '';
      selectedDestinationPoint = null;

      routeCalculated = false;
      routePoints = [];

      roadDistanceKm = null;
      roadDurationMinutes = null;
    });

    final String query =
        value.trim();

    if (query.length < 3) {
      setState(() {
        destinationSuggestions = [];
        isSearchingDestination = false;
      });

      return;
    }

    _destinationSearchTimer = Timer(
      const Duration(milliseconds: 600),
      () {
        searchDestination(query);
      },
    );
  }

  // ============================================================
  // PHOTON SEARCH
  // ============================================================

  Future<void> searchDestination(
    String query,
  ) async {
    if (query.trim().length < 3) {
      return;
    }

    if (currentPosition == null) {
      return;
    }

    setState(() {
      isSearchingDestination = true;
    });

    try {
      final double userLat =
          currentPosition!.latitude;

      final double userLon =
          currentPosition!.longitude;

      final Uri url = Uri.https(
        'photon.komoot.io',
        '/api/',
        {
          'q': query,
          'lat': userLat.toString(),
          'lon': userLon.toString(),
          'limit': '15',
          'lang': 'en',
          'location_bias_scale': '0.2',
        },
      );

      final response =
          await http.get(
        url,
        headers: {
          'User-Agent':
              'RideShareApp/1.0 (Flutter OpenStreetMap app)',
          'Accept-Language': 'en',
          'Accept':
              'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Photon search failed',
        );
      }

      final dynamic decoded =
          jsonDecode(response.body);

      if (decoded
          is! Map<String, dynamic>) {
        throw Exception(
          'Invalid Photon response',
        );
      }

      final dynamic features =
          decoded['features'];

      if (features is! List) {
        throw Exception(
          'Photon features not found',
        );
      }

      final List<DestinationResult>
          results = [];

      for (final feature in features) {
        if (feature is! Map) {
          continue;
        }

        final dynamic properties =
            feature['properties'];

        final dynamic geometry =
            feature['geometry'];

        if (properties is! Map ||
            geometry is! Map) {
          continue;
        }

        final dynamic coordinates =
            geometry['coordinates'];

        if (coordinates is! List ||
            coordinates.length < 2) {
          continue;
        }

        final double? longitude =
            double.tryParse(
          coordinates[0].toString(),
        );

        final double? latitude =
            double.tryParse(
          coordinates[1].toString(),
        );

        if (latitude == null ||
            longitude == null) {
          continue;
        }

        final Map<String, dynamic>
            props =
            Map<String, dynamic>.from(
          properties,
        );

        final String name =
            props['name']
                    ?.toString()
                    .trim() ??
                '';

        if (name.isEmpty) {
          continue;
        }

        final String street =
            props['street']
                    ?.toString()
                    .trim() ??
                '';

        final String houseNumber =
            props['housenumber']
                    ?.toString()
                    .trim() ??
                '';

        final String city =
            getPhotonAddressPart(
          props,
          [
            'city',
            'district',
            'locality',
          ],
        );

        final String state =
            props['state']
                    ?.toString()
                    .trim() ??
                '';

        final String postcode =
            props['postcode']
                    ?.toString()
                    .trim() ??
                '';

        final double distanceKm =
            calculateDistanceKm(
          userLat,
          userLon,
          latitude,
          longitude,
        );

        final String displayName =
            buildPhotonDisplayName(
          name: name,
          street: street,
          houseNumber: houseNumber,
          city: city,
          state: state,
          postcode: postcode,
        );

        results.add(
          DestinationResult(
            name: displayName,
            latitude: latitude,
            longitude: longitude,
            city: city,
            state: state,
            distanceKm: distanceKm,
          ),
        );
      }

      final Map<String,
              DestinationResult>
          uniqueResults = {};

      for (final result in results) {
        final String key =
            '${result.name.toLowerCase()}_${result.latitude.toStringAsFixed(5)}_${result.longitude.toStringAsFixed(5)}';

        uniqueResults[key] =
            result;
      }

      final List<DestinationResult>
          finalResults =
          uniqueResults.values.toList();

      final String currentCity =
          await getCurrentCity();

      final String currentState =
          await getCurrentState();

      finalResults.sort(
        (a, b) {
          final bool aSameCity =
              isSameLocationName(
            a.city,
            currentCity,
          );

          final bool bSameCity =
              isSameLocationName(
            b.city,
            currentCity,
          );

          if (aSameCity &&
              !bSameCity) {
            return -1;
          }

          if (!aSameCity &&
              bSameCity) {
            return 1;
          }

          final bool aSameState =
              isSameLocationName(
            a.state,
            currentState,
          );

          final bool bSameState =
              isSameLocationName(
            b.state,
            currentState,
          );

          if (aSameState &&
              !bSameState) {
            return -1;
          }

          if (!aSameState &&
              bSameState) {
            return 1;
          }

          return a.distanceKm
              .compareTo(
            b.distanceKm,
          );
        },
      );

      final List<DestinationResult>
          limitedResults =
          finalResults.take(8).toList();

      if (!mounted) return;

      setState(() {
        destinationSuggestions =
            limitedResults;

        isSearchingDestination = false;
      });
    } catch (e) {
      debugPrint(
        'Photon destination error: $e',
      );

      if (!mounted) return;

      setState(() {
        destinationSuggestions = [];
        isSearchingDestination = false;
      });
    }
  }

  String getPhotonAddressPart(
    Map<String, dynamic> properties,
    List<String> keys,
  ) {
    for (final key in keys) {
      final String value =
          properties[key]
                  ?.toString()
                  .trim() ??
              '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  String buildPhotonDisplayName({
    required String name,
    required String street,
    required String houseNumber,
    required String city,
    required String state,
    required String postcode,
  }) {
    final List<String> parts = [];

    parts.add(name);

    if (street.isNotEmpty &&
        street.toLowerCase() !=
            name.toLowerCase()) {
      if (houseNumber.isNotEmpty) {
        parts.add(
          '$street $houseNumber',
        );
      } else {
        parts.add(street);
      }
    }

    if (city.isNotEmpty &&
        city.toLowerCase() !=
            name.toLowerCase()) {
      parts.add(city);
    }

    if (state.isNotEmpty &&
        state.toLowerCase() !=
            city.toLowerCase()) {
      parts.add(state);
    }

    if (postcode.isNotEmpty) {
      parts.add(postcode);
    }

    return parts.join(', ');
  }

  Future<String> getCurrentCity() async {
    try {
      if (currentPosition == null) {
        return '';
      }

      final List<Placemark> placemarks =
          await placemarkFromCoordinates(
        currentPosition!.latitude,
        currentPosition!.longitude,
      );

      if (placemarks.isEmpty) {
        return '';
      }

      return placemarks.first.locality?.trim() ??
          '';
    } catch (e) {
      return '';
    }
  }

  Future<String> getCurrentState() async {
    try {
      if (currentPosition == null) {
        return '';
      }

      final List<Placemark> placemarks =
          await placemarkFromCoordinates(
        currentPosition!.latitude,
        currentPosition!.longitude,
      );

      if (placemarks.isEmpty) {
        return '';
      }

      return placemarks.first.administrativeArea
              ?.trim() ??
          '';
    } catch (e) {
      return '';
    }
  }

  bool isSameLocationName(
    String a,
    String b,
  ) {
    if (a.trim().isEmpty ||
        b.trim().isEmpty) {
      return false;
    }

    return a.trim().toLowerCase() ==
        b.trim().toLowerCase();
  }

  double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm =
        6371.0;

    final double dLat =
        degreesToRadians(
      lat2 - lat1,
    );

    final double dLon =
        degreesToRadians(
      lon2 - lon1,
    );

    final double a =
        math.sin(dLat / 2) *
                math.sin(dLat / 2) +
            math.cos(
                  degreesToRadians(
                    lat1,
                  ),
                ) *
                math.cos(
                  degreesToRadians(
                    lat2,
                  ),
                ) *
                math.sin(dLon / 2) *
                math.sin(dLon / 2);

    final double c =
        2 *
            math.atan2(
              math.sqrt(a),
              math.sqrt(1 - a),
            );

    return earthRadiusKm * c;
  }

  double degreesToRadians(
    double degrees,
  ) {
    return degrees * math.pi / 180.0;
  }

  // ============================================================
  // SELECT DESTINATION
  // ============================================================

  Future<void> selectDestination(
    DestinationResult result,
  ) async {
    FocusScope.of(context).unfocus();

    if (!isPickupConfirmed) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please confirm your starting point first.',
          ),
        ),
      );

      return;
    }

    final LatLng point = LatLng(
      result.latitude,
      result.longitude,
    );

    setState(() {
      selectedDestinationPoint =
          point;

      destinationLocation =
          result.name;

      destinationSelected = true;

      destinationSuggestions = [];

      destinationController.text =
          result.name;

      destinationController.selection =
          TextSelection.fromPosition(
        TextPosition(
          offset:
              destinationController
                  .text
                  .length,
        ),
      );

      routeCalculated = false;
      routePoints = [];

      roadDistanceKm = null;
      roadDurationMinutes = null;
    });

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (!mounted) return;

        try {
          mapController.move(
            point,
            16,
          );
        } catch (e) {
          debugPrint(
            'Map move error: $e',
          );
        }
      },
    );

    await calculateRoadRoute();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Destination selected. Move the map to adjust it.',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // OSRM ROAD ROUTE
  // ============================================================

  Future<void> calculateRoadRoute() async {
    if (selectedPickupPoint == null ||
        selectedDestinationPoint == null) {
      return;
    }

    final LatLng pickup =
        selectedPickupPoint!;

    final LatLng destination =
        selectedDestinationPoint!;

    setState(() {
      isCalculatingRoute = true;
      routeCalculated = false;
    });

    try {
      final String coordinates =
          '${pickup.longitude},${pickup.latitude};'
          '${destination.longitude},${destination.latitude}';

      final Uri url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '$coordinates'
        '?overview=full'
        '&geometries=geojson'
        '&steps=false',
      );

      final response =
          await http.get(
        url,
        headers: {
          'User-Agent':
              'RideShareApp/1.0',
          'Accept':
              'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'OSRM failed',
        );
      }

      final dynamic decoded =
          jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception(
          'Invalid OSRM response',
        );
      }

      if (decoded['code'] != 'Ok') {
        throw Exception(
          'No road route found',
        );
      }

      final dynamic routes =
          decoded['routes'];

      if (routes is! List ||
          routes.isEmpty) {
        throw Exception(
          'No route available',
        );
      }

      final dynamic route =
          routes.first;

      final double distanceMeters =
          double.tryParse(
                route['distance']
                        ?.toString() ??
                    '',
              ) ??
              0;

      final double durationSeconds =
          double.tryParse(
                route['duration']
                        ?.toString() ??
                    '',
              ) ??
              0;

      final dynamic geometry =
          route['geometry'];

      final List<LatLng>
          newRoutePoints = [];

      if (geometry is Map) {
        final dynamic coordinates =
            geometry['coordinates'];

        if (coordinates is List) {
          for (final coordinate
              in coordinates) {
            if (coordinate is! List ||
                coordinate.length < 2) {
              continue;
            }

            final double? longitude =
                double.tryParse(
              coordinate[0].toString(),
            );

            final double? latitude =
                double.tryParse(
              coordinate[1].toString(),
            );

            if (latitude == null ||
                longitude == null) {
              continue;
            }

            newRoutePoints.add(
              LatLng(
                latitude,
                longitude,
              ),
            );
          }
        }
      }

      if (newRoutePoints.isEmpty) {
        throw Exception(
          'Route geometry unavailable',
        );
      }

      if (!mounted) return;

      setState(() {
        routePoints =
            newRoutePoints;

        roadDistanceKm =
            distanceMeters / 1000;

        roadDurationMinutes =
            durationSeconds / 60;

        routeCalculated = true;
        isCalculatingRoute = false;
      });
    } catch (e) {
      debugPrint(
        'OSRM route error: $e',
      );

      if (!mounted) return;

      setState(() {
        isCalculatingRoute = false;
        routeCalculated = false;
        routePoints = [];

        roadDistanceKm = null;
        roadDurationMinutes = null;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to calculate the road route.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // RIDE MODE
  // ============================================================

  void changeRideMode(
    bool rideNow,
  ) {
    setState(() {
      isRideNow = rideNow;
    });

    if (!locationDetected) {
      detectCurrentLocation();
    }
  }

  // ============================================================
  // SCHEDULE DATE
  // ============================================================

  Future<void> pickScheduleDate() async {
    final DateTime now = DateTime.now();

    final DateTime? picked =
        await showDatePicker(
      context: context,
      initialDate:
          selectedScheduleDate ?? now,
      firstDate: now,
      lastDate:
          now.add(
        const Duration(
          days: 30,
        ),
      ),
      helpText:
          'Select ride date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      selectedScheduleDate = picked;
    });
  }

  // ============================================================
  // SCHEDULE TIME
  // ============================================================

  Future<void> pickScheduleTime() async {
    final TimeOfDay? picked =
        await showTimePicker(
      context: context,
      initialTime:
          selectedScheduleTime ??
              TimeOfDay.now(),
      helpText:
          'Select ride time',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      selectedScheduleTime = picked;
    });
  }

  // ============================================================
  // COMBINE SCHEDULE DATE + TIME
  // ============================================================

  DateTime? getScheduledDateTime() {
    if (selectedScheduleDate == null ||
        selectedScheduleTime == null) {
      return null;
    }

    return DateTime(
      selectedScheduleDate!.year,
      selectedScheduleDate!.month,
      selectedScheduleDate!.day,
      selectedScheduleTime!.hour,
      selectedScheduleTime!.minute,
    );
  }

  // ============================================================
  // FORMAT SCHEDULE DATE
  // ============================================================

  String formatScheduleDate(
    DateTime date,
  ) {
    return MaterialLocalizations.of(
      context,
    ).formatMediumDate(date);
  }

  // ============================================================
  // FORMAT SCHEDULE TIME
  // ============================================================

  String formatScheduleTime(
    TimeOfDay time,
  ) {
    return MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(
      time,
      alwaysUse24HourFormat: false,
    );
  }

  // ============================================================
  // VALIDATE SCHEDULE
  // ============================================================

  bool validateSchedule() {
    if (selectedScheduleDate == null) {
      showMessage(
        'Please select a date for your ride.',
      );

      return false;
    }

    if (selectedScheduleTime == null) {
      showMessage(
        'Please select a time for your ride.',
      );

      return false;
    }

    final DateTime? scheduledDateTime =
        getScheduledDateTime();

    if (scheduledDateTime == null) {
      return false;
    }

    if (!scheduledDateTime.isAfter(
      DateTime.now(),
    )) {
      showMessage(
        'Please select a future date and time.',
      );

      return false;
    }

    return true;
  }

  // ============================================================
  // CONTINUE
  // ============================================================

  void continueRide() {
    final String destination =
        destinationController.text.trim();

    // ----------------------------------------------------------
    // COMMON VALIDATION
    // ----------------------------------------------------------

    if (!locationDetected ||
        selectedPickupPoint == null) {
      showMessage(
        'Please select your starting point first.',
      );
      return;
    }

    if (!isPickupConfirmed) {
      showMessage(
        'Please confirm your starting point.',
      );
      return;
    }

    if (!destinationSelected ||
        selectedDestinationPoint == null) {
      showMessage(
        'Please select a destination.',
      );
      return;
    }

    if (destination.isEmpty) {
      showMessage(
        'Please enter your destination.',
      );
      return;
    }

    if (!routeCalculated ||
        roadDistanceKm == null ||
        roadDurationMinutes == null) {
      showMessage(
        'Please wait for the road route to be calculated.',
      );
      return;
    }

    // ----------------------------------------------------------
    // SCHEDULED RIDE
    // ----------------------------------------------------------

    if (!isRideNow) {
      if (!validateSchedule()) {
        return;
      }

      final DateTime scheduledDateTime =
          getScheduledDateTime()!;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ScheduledRideScreen(
            startLocation:
                pickupLocation,
            destination:
                destinationLocation,
            availableSeats:
                selectedSeats,
            startPoint:
                selectedPickupPoint!,
            destinationPoint:
                selectedDestinationPoint!,
            routePoints:
                List<LatLng>.from(
              routePoints,
            ),
            roadDistanceKm:
                roadDistanceKm!,
            roadDurationMinutes:
                roadDurationMinutes!,
            scheduledDateTime:
                scheduledDateTime,
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // RIDE NOW
    // ----------------------------------------------------------

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ActiveRideScreen(
          startLocation:
              pickupLocation,
          destination:
              destinationLocation,
          availableSeats:
              selectedSeats,
          startPoint:
              selectedPickupPoint!,
          destinationPoint:
              selectedDestinationPoint!,
          routePoints:
              List<LatLng>.from(
            routePoints,
          ),
          roadDistanceKm:
              roadDistanceKm!,
          roadDurationMinutes:
              roadDurationMinutes!,
          isScheduled: false,
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // ETA
  // ============================================================

  String formatEta(
    double minutes,
  ) {
    final int totalMinutes =
        minutes.round();

    if (totalMinutes < 1) {
      return 'Less than 1 min';
    }

    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }

    final int hours =
        totalMinutes ~/ 60;

    final int remainingMinutes =
        totalMinutes % 60;

    if (remainingMinutes == 0) {
      return '$hours hr';
    }

    return '$hours hr $remainingMinutes min';
  }

  // ============================================================
  // LOCATION DIALOG
  // ============================================================

  Future<void> showLocationDialog(
    String title,
    String message, {
    bool showSettingsButton = false,
  }) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (showSettingsButton)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  await Geolocator
                      .openAppSettings();
                },
                child: const Text(
                  'Open Settings',
                ),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SEAT
  // ============================================================

  Widget _seatOption(
    int seats,
  ) {
    final bool selected =
        selectedSeats == seats;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedSeats = seats;
          });
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            vertical: 15,
          ),
          decoration:
              BoxDecoration(
            color: selected
                ? Colors.black
                : Colors.white,
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            border: Border.all(
              color: selected
                  ? Colors.black
                  : Colors.grey.shade300,
            ),
          ),
          child: Text(
            '$seats ${seats == 1 ? 'seat' : 'seats'}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.black,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SCHEDULE CARD
  // ============================================================

  Widget _buildScheduleCard() {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.schedule,
                color: Colors.black,
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                'When do you want to ride?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _scheduleSelectionTile(
                  icon: Icons.calendar_month,
                  title: 'Date',
                  value:
                      selectedScheduleDate ==
                              null
                          ? 'Select date'
                          : formatScheduleDate(
                              selectedScheduleDate!,
                            ),
                  onTap:
                      pickScheduleDate,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                    _scheduleSelectionTile(
                  icon: Icons.access_time,
                  title: 'Time',
                  value:
                      selectedScheduleTime ==
                              null
                          ? 'Select time'
                          : formatScheduleTime(
                              selectedScheduleTime!,
                            ),
                  onTap:
                      pickScheduleTime,
                ),
              ),
            ],
          ),

          if (selectedScheduleDate !=
                  null &&
              selectedScheduleTime !=
                  null) ...[
            const SizedBox(
              height: 12,
            ),
            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(12),
              decoration:
                  BoxDecoration(
                color: Colors.green
                    .withOpacity(
                  0.07,
                ),
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      'Scheduled for ${formatScheduleDate(selectedScheduleDate!)} at ${formatScheduleTime(selectedScheduleTime!)}',
                      style:
                          const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scheduleSelectionTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(
        12,
      ),
      child: Container(
        padding:
            const EdgeInsets.all(12),
        decoration:
            BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.black,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color:
                    Colors.grey.shade600,
              ),
            ),
            const SizedBox(
              height: 3,
            ),
            Text(
              value,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool canContinue =
        locationDetected &&
            isPickupConfirmed &&
            destinationSelected &&
            selectedDestinationPoint !=
                null &&
            routeCalculated &&
            (isRideNow ||
                (selectedScheduleDate !=
                        null &&
                    selectedScheduleTime !=
                        null));

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Create Ride',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // RIDE NOW / SCHEDULE
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.all(5),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.grey.shade200,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child:
                          GestureDetector(
                        onTap: () {
                          changeRideMode(
                            true,
                          );
                        },
                        child: Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 13,
                          ),
                          decoration:
                              BoxDecoration(
                            color: isRideNow
                                ? Colors.white
                                : Colors
                                    .transparent,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                          child:
                              const Text(
                            'Ride Now',
                            textAlign:
                                TextAlign.center,
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child:
                          GestureDetector(
                        onTap: () {
                          changeRideMode(
                            false,
                          );
                        },
                        child: Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 13,
                          ),
                          decoration:
                              BoxDecoration(
                            color: !isRideNow
                                ? Colors.white
                                : Colors
                                    .transparent,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                          child:
                              const Text(
                            'Schedule',
                            textAlign:
                                TextAlign.center,
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 28,
              ),

              Text(
                isRideNow
                    ? 'Where are you going?'
                    : 'Plan your ride',
                style:
                    const TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                isRideNow
                    ? 'Set your starting point and destination.'
                    : 'Choose when you want your ride to become active.',
                style:
                    TextStyle(
                  color:
                      Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),

              const SizedBox(
                height: 22,
              ),

              // ==================================================
              // SCHEDULE DATE + TIME
              // ==================================================

              if (!isRideNow) ...[
                _buildScheduleCard(),

                const SizedBox(
                  height: 22,
                ),
              ],

              // ==================================================
              // MAP
              // ==================================================

              if (isDetectingLocation)
                Container(
                  height: 300,
                  width:
                      double.infinity,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                  child:
                      const Center(
                    child:
                        Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(
                          height: 14,
                        ),
                        Text(
                          'Detecting your location...',
                        ),
                      ],
                    ),
                  ),
                )
              else if (locationDetected &&
                  selectedPickupPoint !=
                      null) ...[
                Text(
                  isPickupConfirmed &&
                          selectedDestinationPoint !=
                              null
                      ? 'Adjust destination'
                      : 'Select starting point',
                  style:
                      const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  !isPickupConfirmed
                      ? 'Move the map to place the starting point exactly where you want to begin your ride.'
                      : selectedDestinationPoint ==
                              null
                          ? 'Starting point is locked. Search and select your destination first.'
                          : 'Starting point is locked. Move the map to adjust your destination.',
                  style:
                      TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  child: SizedBox(
                    height: 300,
                    width:
                        double.infinity,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController:
                              mapController,
                          options:
                              MapOptions(
                            initialCenter:
                                selectedPickupPoint!,
                            initialZoom: 17,
                            onPositionChanged:
                                (
                              camera,
                              hasGesture,
                            ) {
                              if (hasGesture) {
                                onMapPositionChanged(
                                  camera,
                                );
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.example.ride_share_app',
                            ),

                            if (routePoints
                                .isNotEmpty)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points:
                                        routePoints,
                                    strokeWidth:
                                        5,
                                    color:
                                        Colors.blue,
                                  ),
                                ],
                              ),

                            MarkerLayer(
                              markers: [
                                Marker(
                                  point:
                                      selectedPickupPoint!,
                                  width: 55,
                                  height: 55,
                                  child:
                                      const Icon(
                                    Icons
                                        .location_pin,
                                    color:
                                        Colors.green,
                                    size: 52,
                                  ),
                                ),

                                if (selectedDestinationPoint !=
                                    null)
                                  Marker(
                                    point:
                                        selectedDestinationPoint!,
                                    width: 55,
                                    height: 55,
                                    child:
                                        const Icon(
                                      Icons
                                          .location_pin,
                                      color:
                                          Colors.red,
                                      size: 52,
                                    ),
                                  ),
                              ],
                            ),

                            RichAttributionWidget(
                              attributions: [
                                TextSourceAttribution(
                                  'OpenStreetMap contributors',
                                ),
                              ],
                            ),
                          ],
                        ),

                        Positioned(
                          top: 12,
                          left: 12,
                          right: 12,
                          child:
                              Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration:
                                BoxDecoration(
                              color: Colors.white
                                  .withOpacity(
                                0.95,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons
                                      .touch_app,
                                  size: 18,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Expanded(
                                  child: Text(
                                    !isPickupConfirmed
                                        ? 'Move map to adjust starting point'
                                        : selectedDestinationPoint ==
                                                null
                                            ? 'Starting point locked'
                                            : 'Move map to adjust destination',
                                    style:
                                        const TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Positioned(
                          right: 12,
                          bottom: 12,
                          child:
                              FloatingActionButton
                                  .small(
                            heroTag:
                                'currentLocationButton',
                            backgroundColor:
                                Colors.white,
                            foregroundColor:
                                isPickupConfirmed
                                    ? Colors.grey
                                    : Colors.black,
                            onPressed:
                                isPickupConfirmed
                                    ? null
                                    : moveToCurrentLocation,
                            child:
                                const Icon(
                              Icons
                                  .my_location,
                            ),
                          ),
                        ),

                        Positioned(
                          left: 8,
                          bottom: 8,
                          child:
                              Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            color: Colors.white
                                .withOpacity(
                              0.85,
                            ),
                            child:
                                const Text(
                              '© OpenStreetMap contributors',
                              style:
                                  TextStyle(
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                // ==================================================
                // STARTING POINT CARD
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets.all(
                    14,
                  ),
                  decoration:
                      BoxDecoration(
                    color: isPickupConfirmed
                        ? Colors.green
                            .withOpacity(
                            0.08,
                          )
                        : Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    border: Border.all(
                      color: isPickupConfirmed
                          ? Colors.green
                          : Colors.grey
                              .shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPickupConfirmed
                            ? Icons.check
                            : Icons.location_on,
                        color:
                            isPickupConfirmed
                                ? Colors.green
                                : Colors.red,
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPickupConfirmed
                                  ? 'Starting point locked'
                                  : 'Selected starting point',
                              style:
                                  const TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            isUpdatingAddress
                                ? const Text(
                                    'Updating address...',
                                  )
                                : Text(
                                    pickupLocation,
                                    style:
                                        const TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w500,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 48,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        isUpdatingAddress
                            ? null
                            : confirmPickupLocation,
                    icon: Icon(
                      isPickupConfirmed
                          ? Icons.check
                          : Icons.location_on,
                    ),
                    label: Text(
                      isPickupConfirmed
                          ? 'Starting Point Locked'
                          : 'Confirm Starting Point',
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          isPickupConfirmed
                              ? Colors.green
                              : Colors.black,
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),
              ],

              // ==================================================
              // DESTINATION
              // ==================================================

              const Text(
                'Destination',
                style:
                    TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              TextField(
                controller:
                    destinationController,
                onChanged:
                    onDestinationChanged,
                textInputAction:
                    TextInputAction.search,
                decoration:
                    InputDecoration(
                  hintText:
                      'Search destination',
                  prefixIcon:
                      const Icon(
                    Icons.location_on_outlined,
                  ),
                  suffixIcon:
                      isSearchingDestination
                          ? const Padding(
                              padding:
                                  EdgeInsets.all(
                                14,
                              ),
                              child:
                                  SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              ),
                            )
                          : destinationSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color:
                                      Colors.green,
                                )
                              : null,
                  filled: true,
                  fillColor:
                      Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),

              if (destinationSuggestions
                  .isNotEmpty)
                Container(
                  margin:
                      const EdgeInsets.only(
                    top: 10,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    border:
                        Border.all(
                      color:
                          Colors.grey.shade300,
                    ),
                  ),
                  child:
                      ListView.separated(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount:
                        destinationSuggestions
                            .length,
                    separatorBuilder:
                        (
                      context,
                      index,
                    ) =>
                            Divider(
                      height: 1,
                      color:
                          Colors.grey.shade200,
                    ),
                    itemBuilder:
                        (
                      context,
                      index,
                    ) {
                      final result =
                          destinationSuggestions[
                              index];

                      return InkWell(
                        onTap: () {
                          selectDestination(
                            result,
                          );
                        },
                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .all(
                            14,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons
                                    .location_on,
                                color:
                                    Colors.red,
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Expanded(
                                child: Text(
                                  result.name,
                                  maxLines: 3,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight
                                            .w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              if (destinationSelected) ...[
                const SizedBox(
                  height: 12,
                ),

                Container(
                  padding:
                      const EdgeInsets.all(
                    14,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.red
                        .withOpacity(
                      0.05,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    border: Border.all(
                      color: Colors.red
                          .withOpacity(
                        0.2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Destination',
                              style:
                                  TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              isUpdatingDestinationAddress
                                  ? 'Updating destination...'
                                  : destinationLocation,
                              style:
                                  const TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                // ==================================================
                // ROUTE INFO
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    border: Border.all(
                      color:
                          Colors.grey.shade300,
                    ),
                  ),
                  child: isCalculatingRoute
                      ? const Row(
                          children: [
                            SizedBox(
                              height: 22,
                              width: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                            SizedBox(
                              width: 12,
                            ),
                            Text(
                              'Calculating road route...',
                            ),
                          ],
                        )
                      : routeCalculated
                          ? Row(
                              children: [
                                Expanded(
                                  child:
                                      _routeInfoItem(
                                    Icons.route,
                                    '${roadDistanceKm!.toStringAsFixed(1)} km',
                                    'Road distance',
                                  ),
                                ),
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: Colors
                                      .grey
                                      .shade300,
                                ),
                                Expanded(
                                  child:
                                      _routeInfoItem(
                                    Icons.access_time,
                                    formatEta(
                                      roadDurationMinutes!,
                                    ),
                                    'Estimated time',
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Road route could not be calculated yet.',
                            ),
                ),
              ],

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // SEATS
              // ==================================================

              const Text(
                'Available seats',
                style:
                    TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Row(
                children: [
                  _seatOption(1),
                  const SizedBox(
                    width: 12,
                  ),
                  _seatOption(2),
                ],
              ),

              const SizedBox(
                height: 28,
              ),

              // ==================================================
              // INFO
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.blue
                      .withOpacity(
                    0.06,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child: Text(
                        isRideNow
                            ? 'Your ride will become visible to matching passengers after you continue.'
                            : 'Your scheduled ride will become active at the selected date and time.',
                        style:
                            const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // ==================================================
              // CONTINUE / SCHEDULE RIDE
              // ==================================================

              SizedBox(
                width:
                    double.infinity,
                height: 54,
                child:
                    ElevatedButton(
                  onPressed:
                      canContinue
                          ? continueRide
                          : null,
                  style:
                      ElevatedButton.styleFrom(
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  child:
                      Text(
                    isRideNow
                        ? 'Start Ride'
                        : 'Schedule Ride',
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              if (locationDetected)
                Center(
                  child: Text(
                    !routeCalculated
                        ? destinationSelected
                            ? 'Calculating your road route...'
                            : 'Search and select your destination'
                        : !isRideNow &&
                                (selectedScheduleDate ==
                                        null ||
                                    selectedScheduleTime ==
                                        null)
                            ? 'Select your schedule date and time'
                            : '✓ Route calculated successfully',
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color:
                          routeCalculated &&
                                  (isRideNow ||
                                      (selectedScheduleDate !=
                                              null &&
                                          selectedScheduleTime !=
                                              null))
                              ? Colors.green
                                  .shade700
                              : Colors.grey
                                  .shade600,
                      fontWeight:
                          FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),

              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ROUTE INFO ITEM
  // ============================================================

  Widget _routeInfoItem(
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 22,
          color: Colors.blue,
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          value,
          style:
              const TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 2,
        ),
        Text(
          label,
          style:
              TextStyle(
            fontSize: 11,
            color:
                Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// DESTINATION RESULT
// ================================================================

class DestinationResult {
  final String name;
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final double distanceKm;

  DestinationResult({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.distanceKm,
  });
}