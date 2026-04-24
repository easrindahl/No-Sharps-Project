import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../presenters/report_presenter.dart';

class LocationSuggestion {
  final String description;
  final String mainText;
  final String secondaryText;
  final String placeId;

  LocationSuggestion({
    required this.description,
    required this.mainText,
    required this.secondaryText,
    required this.placeId,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      description: json['description'] ?? '',
      mainText: json['description'] ?? '',
      secondaryText: json['types']?.isNotEmpty == true
          ? (json['types'] as List).first.toString()
          : '',
      placeId: json['place_id'] ?? '',
    );
  }
}

class CreateReportView extends StatefulWidget {
  const CreateReportView({super.key});

  @override
  State<CreateReportView> createState() => _CreateReportViewState();
}

class _CreateReportViewState extends State<CreateReportView> {
  final _formKey = GlobalKey<FormState>();
  String? _location;
  File? _imageFile;
  bool _loading = false;
  bool _gettingLocation = false;
  double? _latitude;
  double? _longitude;
  String? _selectedPlaceId;
  bool _settingLocationProgrammatically = false;
  final _picker = ImagePicker();
  late final ReportPresenter presenter;
  final _locationController = TextEditingController();
  List<LocationSuggestion> _locationSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    presenter = ReportPresenter(Supabase.instance.client);
    _locationController.addListener(_onLocationChanged);
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _onLocationChanged() {
    if (_settingLocationProgrammatically) return;

    if (_selectedPlaceId != null && _locationController.text != _location) {
      setState(() {
        _selectedPlaceId = null;
        _latitude = null;
        _longitude = null;
      });
    }

    if (_locationController.text.isEmpty) {
      setState(() {
        _locationSuggestions = [];
        _showSuggestions = false;
        _selectedPlaceId = null;
        _latitude = null;
        _longitude = null;
      });
      return;
    }
    _getLocationSuggestions(_locationController.text);
  }

  Future<LatLng?> _fetchPlaceLatLng(String placeId) async {
    if (placeId.isEmpty) return null;
    try {
      const String googleApiKey = 'AIzaSyCqQ5m2e49uP6D_HfDL-W2otxC3wLuVKbQ';
      final url =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$googleApiKey';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      if (json['status'] != 'OK') return null;
      final result = json['result'];
      final geometry = result?['geometry'];
      final location = geometry?['location'];
      final lat = (location?['lat'] as num?)?.toDouble();
      final lng = (location?['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return LatLng(lat, lng);
    } catch (_) {
      return null;
    }
  }

  Future<void> _getLocationSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _locationSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    try {
      const String googleApiKey = 'AIzaSyCqQ5m2e49uP6D_HfDL-W2otxC3wLuVKbQ';

      final String url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$googleApiKey&components=country:us';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> predictions = json['predictions'] ?? [];
        final suggestions = predictions
            .map((p) => LocationSuggestion.fromJson(p))
            .toList();

        if (mounted) {
          setState(() {
            _locationSuggestions = suggestions;
            _showSuggestions = suggestions.isNotEmpty;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationSuggestions = [];
          _showSuggestions = false;
        });
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _gettingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        setState(() => _gettingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        final address =
            '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';
        setState(() {
          _settingLocationProgrammatically = true;
          _locationController.text = address;
          _location = address;
          _selectedPlaceId = null;
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        _settingLocationProgrammatically = false;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Submit Needle Disposal'),
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Submit Needle Disposal',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload a photo of the needle and specify its location for safe disposal.',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Upload Needle Image:',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          if (_imageFile != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _imageFile!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 140,
                              ),
                            ),
                          if (_imageFile != null) const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _pickImageFromSource(
                                ImageSource.camera,
                              ),
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: const Text('Take photo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A7D46),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImageFromSource(
                                ImageSource.gallery,
                              ),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Select from gallery'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1F5133),
                                backgroundColor: const Color(0xFFEFF7F0),
                                side:
                                    const BorderSide(color: Color(0xFFAEE5B3)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Location:',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Column(
                          children: [
                            TextFormField(
                              controller: _locationController,
                              decoration: InputDecoration(
                                hintText:
                                    'Enter location or use your current location',
                                border: const OutlineInputBorder(),
                                suffixIcon: _gettingLocation
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.location_on),
                                        onPressed: _gettingLocation
                                            ? null
                                            : _useCurrentLocation,
                                        tooltip: 'Use my location',
                                      ),
                              ),
                              onSaved: (val) => _location = val,
                              validator: (val) => (val == null || val.isEmpty)
                                  ? 'Location required'
                                  : null,
                            ),
                            if (_locationController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Tip: Tap the location icon to use your GPS location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            if (_showSuggestions &&
                                _locationSuggestions.isNotEmpty)
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(color: Colors.grey.shade300),
                                    right: BorderSide(color: Colors.grey.shade300),
                                    bottom:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(4),
                                    bottomRight: Radius.circular(4),
                                  ),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _locationSuggestions.length,
                                  itemBuilder: (context, index) {
                                    final suggestion =
                                        _locationSuggestions[index];
                                    return ListTile(
                                      leading: const Icon(
                                        Icons.location_on_outlined,
                                      ),
                                      title: Text(suggestion.mainText),
                                      subtitle: Text(
                                        suggestion.secondaryText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () {
                                        () async {
                                          setState(() {
                                            _settingLocationProgrammatically =
                                                true;
                                            _locationController.text =
                                                suggestion.description;
                                            _location = suggestion.description;
                                            _selectedPlaceId =
                                                suggestion.placeId.isNotEmpty
                                                    ? suggestion.placeId
                                                    : null;
                                            _showSuggestions = false;
                                          });
                                          _settingLocationProgrammatically =
                                              false;

                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final coords = await _fetchPlaceLatLng(
                                            suggestion.placeId,
                                          );
                                          if (!mounted) return;
                                          if (coords == null) {
                                            setState(() {
                                              _selectedPlaceId = null;
                                              _latitude = null;
                                              _longitude = null;
                                            });
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Couldn’t resolve that address; we’ll use your current location on submit.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          setState(() {
                                            _latitude = coords.latitude;
                                            _longitude = coords.longitude;
                                          });
                                        }();
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF7F0),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFAEE5B3)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Safety Guidelines',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F5133),
                            ),
                          ),
                          SizedBox(height: 14),
                          Text(
                            '• Wear gloves while handling needles.',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color: Color(0xFF2A5D3A),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '• Do not attempt to recap the needle.',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color: Color(0xFF2A5D3A),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '• Dispose of needles in a designated sharps container.',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color: Color(0xFF2A5D3A),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '• Wash your hands thoroughly after disposal.',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color: Color(0xFF2A5D3A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (!mounted || picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
    });
  }

  Future<void> _submitReport() async {
    if (!mounted) return;

    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      _location = _locationController.text;
      setState(() => _loading = true);

      try {
        String? imagePath;
        if (_imageFile != null) {
          imagePath = await presenter.uploadImage(_imageFile!);
        }

        double? latitude = _latitude;
        double? longitude = _longitude;

        if (latitude == null || longitude == null) {
          // User chose free-typed location; fallback to GPS coordinates.
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Enable location to submit this report (required for map node).',
                ),
              ),
            );
            return;
          }

          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          latitude = pos.latitude;
          longitude = pos.longitude;
        }

        await presenter.submitReport(
          imagePath: imagePath,
          location: _location ?? '',
          latitude: latitude,
          longitude: longitude,
        );

        if (!mounted) return;

        final bool isLoggedIn = Supabase.instance.client.auth.currentUser != null;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLoggedIn
                  ? 'Report submitted! You earned 1 point.'
                  : 'Report submitted!',
            ),
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }
}
