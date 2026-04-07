import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../presenters/report_presenter.dart';

class LocationSuggestion {
  final String description;
  final String mainText;
  final String secondaryText;

  LocationSuggestion({
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      description: json['description'] ?? '',
      mainText: json['description'] ?? '',
      secondaryText: json['types']?.isNotEmpty == true 
          ? (json['types'] as List).first.toString()
          : '',
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
    if (_locationController.text.isEmpty) {
      setState(() {
        _locationSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _getLocationSuggestions(_locationController.text);
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
      
      // Only make API calls if a valid API key is configured
      // if (googleApiKey == 'AIzaSyCqQ5m2e49uP6D_HfDL-W2otxC3wLuVKbQ') {
      //   setState(() {
      //     _locationSuggestions = [];
      //     _showSuggestions = false;
      //   });
      //   return;
      // }

      final String url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$googleApiKey&components=country:us';

      final response = await http.get(Uri.parse(url), headers: {
        'Accept': 'application/json',
      });

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
      // Check location permissions
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

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Convert coordinates to address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        final address =
            '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';
        setState(() {
          _locationController.text = address;
          _location = address;
        });
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
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
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload a photo of the needle and specify its location for safe disposal.',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Upload Needle Image:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: _imageFile == null
                          ? const Icon(
                              Icons.camera_alt_outlined,
                              size: 48,
                              color: Colors.grey,
                            )
                          : Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Location:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Column(
                      children: [
                        TextFormField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            hintText: 'Enter location or use your current location',
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
                        if (_showSuggestions && _locationSuggestions.isNotEmpty)
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(color: Colors.grey.shade300),
                                right: BorderSide(color: Colors.grey.shade300),
                                bottom: BorderSide(color: Colors.grey.shade300),
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
                                final suggestion = _locationSuggestions[index];
                                return ListTile(
                                  leading: const Icon(Icons.location_on_outlined),
                                  title: Text(suggestion.mainText),
                                  subtitle: Text(
                                    suggestion.secondaryText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _locationController.text =
                                          suggestion.description;
                                      _location = suggestion.description;
                                      _showSuggestions = false;
                                    });
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
  backgroundColor: Colors.grey[50],
); 
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _submitReport() async {
    if (!mounted) return;
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      _location = _locationController.text;
      setState(() => _loading = true);
      try {
        String? imagePath;
        String? imagePath;
        if (_imageFile != null) {
          imagePath = await presenter.uploadImage(_imageFile!);
          imagePath = await presenter.uploadImage(_imageFile!);
        }
        await presenter.submitReport(
          imagePath: imagePath,
          location: _location ?? '',
        );
        await presenter.submitReport(
          imagePath: imagePath,
          location: _location ?? '',
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Report submitted!')));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Report submitted!')));
        Navigator.pop(context); // Return to previous page (home)
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }
}
