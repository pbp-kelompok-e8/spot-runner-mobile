import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spot_runner_mobile/core/widgets/left_drawer.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class EditEventFormPage extends StatefulWidget {
  final Map<String, dynamic> event;

  const EditEventFormPage({super.key, required this.event});

  @override
  State<EditEventFormPage> createState() => _EditEventFormPageState();
}

class _EditEventFormPageState extends State<EditEventFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _eventName = "";
  String _description = "";
  int _totalParticipants = 0;
  String _location = "jakarta_barat";
  String _image = "";
  String _image2 = "";
  String _image3 = "";
  String _contactPerson = "";
  int _coin = 0;
  DateTime _eventDate = DateTime.now();
  DateTime _registDeadline = DateTime.now();

  final TextEditingController _eventDateController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final df = DateFormat('yyyy-MM-dd HH:mm');

    final data = widget.event;

    _eventName = data['name'] ?? "";
    _description = data['description'] ?? "";
    _totalParticipants = data['capacity'] ?? 0;

    String loc = data['location'] ?? "jakarta_barat";
    _location = _cities.contains(loc) ? loc : _cities[0];

    _image = data['image'] ?? "";
    _image2 = data['image2'] ?? "";
    _image3 = data['image3'] ?? "";
    _contactPerson = data['contact'] ?? "";
    _coin = data['coin'] ?? 0;

    if (data['event_date'] != null)
      _eventDate = DateTime.parse(data['event_date']);
    if (data['regist_deadline'] != null)
      _registDeadline = DateTime.parse(data['regist_deadline']);

    if (data['event_categories'] != null) {
      _selectedCategories = List<String>.from(data['event_categories']);
    }

    _eventDateController.text = df.format(_eventDate);
    _deadlineController.text = df.format(_registDeadline);
  }

  @override
  void dispose() {
    _eventDateController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  bool _isPast(DateTime d) {
    return d.isBefore(DateTime.now());
  }

  Future<void> _pickDateTime({
    required BuildContext context,
    required DateTime initialDate,
    required ValueChanged<DateTime> onPicked,
    required TextEditingController controller,
  }) async {
    final Color myColor = const Color(0xFF1D4ED8);

    final DateTime? datePart = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: myColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: myColor),
            ),
          ),
          child: child!,
        );
      },
      // ------------------------------------
    );

    if (datePart != null) {
      if (!context.mounted) return;

      final TimeOfDay? timePart = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: myColor,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              timePickerTheme: TimePickerThemeData(
                dialHandColor: myColor,
                hourMinuteColor: MaterialStateColor.resolveWith(
                  (states) => states.contains(MaterialState.selected)
                      ? myColor
                      : Colors.grey.shade200,
                ),
                hourMinuteTextColor: MaterialStateColor.resolveWith(
                  (states) => states.contains(MaterialState.selected)
                      ? Colors.white
                      : Colors.black,
                ),
                dayPeriodColor: MaterialStateColor.resolveWith(
                  (states) => states.contains(MaterialState.selected)
                      ? myColor
                      : Colors.transparent,
                ),
                dayPeriodTextColor: MaterialStateColor.resolveWith(
                  (states) => states.contains(MaterialState.selected)
                      ? Colors.white
                      : Colors.black87,
                ),
                dayPeriodBorderSide: BorderSide(color: myColor),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: myColor),
              ),
            ),
            child: child!,
          );
        },
      );

      if (timePart != null) {
        final DateTime combined = DateTime(
          datePart.year,
          datePart.month,
          datePart.day,
          timePart.hour,
          timePart.minute,
        );

        setState(() {
          onPicked(combined);
          controller.text = DateFormat('yyyy-MM-dd HH:mm').format(combined);
          _formKey.currentState?.validate();
        });
      }
    }
  }

  final List<String> _cities = [
    'jakarta_barat',
    'jakarta_timur',
    'jakarta_utara',
    'jakarta_selatan',
    'jakarta_pusat',
    'bekasi',
    'tangerang',
    'bogor',
    'depok',
  ];

  final List<String> _categories = [
    "fun_run",
    "5k",
    "10k",
    "half_marathon",
    "full_marathon",
  ];
  List<String> _selectedCategories = [];

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final dynamic sessionUserId = request.jsonData.containsKey('user_id')
        ? request.jsonData['user_id']
        : null;

    final int? eventUserId = sessionUserId is int
        ? sessionUserId
        : sessionUserId != null
        ? int.tryParse(sessionUserId.toString())
        : null;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Spot Runner'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D4ED8),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: const LeftDrawer(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 25,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: const [
                              Text(
                                'Edit Event',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Edit your marathon event details',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        _buildInputLabel("Event Name"),
                        TextFormField(
                          initialValue: _eventName,
                          decoration: _buildInputDecoration("Enter event name"),
                          onChanged: (value) =>
                              setState(() => _eventName = value),
                          validator: (value) => (value == null || value.isEmpty)
                              ? "This field cannot be empty!"
                              : null,
                        ),
                        const SizedBox(height: 16),

                        _buildInputLabel("Event Description"),
                        TextFormField(
                          initialValue: _description,
                          maxLines: 4,
                          decoration: _buildInputDecoration(
                            "Describe what the event is about...",
                          ),
                          onChanged: (value) =>
                              setState(() => _description = value),
                          validator: (value) => (value == null || value.isEmpty)
                              ? "This field cannot be empty!"
                              : null,
                        ),
                        const SizedBox(height: 16),

                        _buildInputLabel("Location"),
                        DropdownButtonFormField<String>(
                          value: _location,
                          decoration: _buildInputDecoration(
                            "Select Location",
                            suffixIcon: const Icon(Icons.location_on_outlined),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: _cities
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(
                                    cat[0].toUpperCase() +
                                        cat.substring(1).replaceAll("_", " "),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (newValue) =>
                              setState(() => _location = newValue!),
                        ),
                        const SizedBox(height: 16),

                        _buildInputLabel("Event Date"),
                        TextFormField(
                          controller: _eventDateController,
                          decoration: _buildInputDecoration(
                            "Select Date & Time",
                            suffixIcon: const Icon(Icons.access_time, size: 20),
                          ),
                          readOnly: true,
                          onTap: () => _pickDateTime(
                            context: context,
                            initialDate: _eventDate,
                            onPicked: (d) => _eventDate = d,
                            controller: _eventDateController,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "Required";
                            final parsed = DateFormat(
                              'yyyy-MM-dd HH:mm',
                            ).parse(value);
                            if (_isPast(parsed)) return "Invalid date/time";
                            if (_deadlineController.text.isNotEmpty) {
                              final dl = DateFormat(
                                'yyyy-MM-dd HH:mm',
                              ).parse(_deadlineController.text);
                              if (parsed.isBefore(dl))
                                return "Must be after deadline";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildInputLabel("Registration Deadline"),
                        TextFormField(
                          controller: _deadlineController,
                          decoration: _buildInputDecoration(
                            "Select Date & Time",
                            suffixIcon: const Icon(Icons.access_time, size: 20),
                          ),
                          readOnly: true,
                          onTap: () => _pickDateTime(
                            context: context,
                            initialDate: _registDeadline,
                            onPicked: (d) => _registDeadline = d,
                            controller: _deadlineController,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "Required";
                            final parsed = DateFormat(
                              'yyyy-MM-dd HH:mm',
                            ).parse(value);
                            if (_isPast(parsed)) return "Invalid date/time";
                            if (_eventDateController.text.isNotEmpty) {
                              final ed = DateFormat(
                                'yyyy-MM-dd HH:mm',
                              ).parse(_eventDateController.text);
                              if (parsed.isAfter(ed))
                                return "Must be before event";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildInputLabel("Contact Person"),
                        TextFormField(
                          initialValue: _contactPerson,
                          decoration: _buildInputDecoration(
                            "Enter phone number",
                          ),
                          onChanged: (value) =>
                              setState(() => _contactPerson = value),
                          validator: (value) => (value == null || value.isEmpty)
                              ? "This field cannot be empty!"
                              : null,
                        ),
                        const SizedBox(height: 16),

                        _buildInputLabel("Max Participants"),
                        TextFormField(
                          initialValue: _totalParticipants.toString(),
                          decoration: _buildInputDecoration(
                            "0",
                            suffixIcon: const Icon(Icons.people_outline),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => setState(
                            () => _totalParticipants =
                                int.tryParse(value ?? '') ?? 0,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "Required";
                            final int? participants = int.tryParse(value);
                            if (participants == null || participants < 0)
                              return "Invalid number";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildInputLabel("Coin Reward"),
                        TextFormField(
                          initialValue: _coin.toString(),
                          decoration: _buildInputDecoration(
                            "0",
                            suffixIcon: const Icon(Icons.people_outline),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => setState(
                            () => _coin = int.tryParse(value ?? '') ?? 0,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "Required";
                            final int? participants = int.tryParse(value);
                            if (participants == null || participants < 0)
                              return "Invalid number";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildInputLabel("Event Category"),
                        Column(
                          children: _categories.map((category) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _selectedCategories.contains(
                                        category,
                                      ),
                                      activeColor: const Color(0xFF1D4ED8),
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedCategories.add(category);
                                          } else {
                                            _selectedCategories.remove(
                                              category,
                                            );
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    category[0].toUpperCase() +
                                        category
                                            .substring(1)
                                            .replaceAll("_", " "),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        _buildInputLabel("Image URL (Optional)"),
                        TextFormField(
                          initialValue: _image,
                          decoration: _buildInputDecoration(
                            "https://example.com/image.jpg",
                            suffixIcon: const Icon(Icons.image_outlined),
                          ),
                          keyboardType: TextInputType.url,
                          onChanged: (value) => setState(() => _image = value),
                          validator: _validateUrl,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),
                        const SizedBox(height: 16),

                        _buildInputLabel("Image 2 URL (Optional)"),
                        TextFormField(
                          initialValue: _image2,
                          decoration: _buildInputDecoration(
                            "https://example.com/image.jpg",
                            suffixIcon: const Icon(Icons.image_outlined),
                          ),
                          keyboardType: TextInputType.url,
                          onChanged: (value) => setState(() => _image2 = value),
                          validator: _validateUrl,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),
                        const SizedBox(height: 16),

                        _buildInputLabel("Image 3 URL (Optional)"),
                        TextFormField(
                          initialValue: _image3,
                          decoration: _buildInputDecoration(
                            "https://example.com/image.jpg",
                            suffixIcon: const Icon(Icons.image_outlined),
                          ),
                          keyboardType: TextInputType.url,
                          onChanged: (value) => setState(() => _image3 = value),
                          validator: _validateUrl,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      if (_selectedCategories.isEmpty) {
                        // Tampilkan pesan error jika kosong
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Please select at least one category.",
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (_formKey.currentState!.validate()) {
                        // Tampilkan loading
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sending data...')),
                        );
                        String id = widget.event['id'].toString();

                        try {
                          final response = await request.postJson(
                            'http://localhost:8000/event/edit-flutter/$id/',
                            jsonEncode({
                              "name": _eventName,
                              "description": _description,
                              "location": _location,
                              "image1": _image,
                              "image2": _image2,
                              "image3": _image3,
                              "event_date": _eventDate.toIso8601String(),
                              "regist_deadline": _registDeadline
                                  .toIso8601String(),
                              "contact": _contactPerson,
                              "capacity": _totalParticipants,
                              "coin": _coin,
                              "total_participans": 0,
                              "categories": _selectedCategories,
                            }),
                          );

                          if (context.mounted) {
                            if (response['status'] == 'success') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Success! Event saved."),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context, true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Failed: ${response['message']}",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: const Text(
                      "Edit",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    final Uri? uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return "Invalid URL format";
    }
    return null;
  }
}
