import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:spot_runner_mobile/core/config/api_config.dart';
import 'package:spot_runner_mobile/core/utils/safe_api_call.dart';

class EditEOProfilePage extends StatefulWidget {
  const EditEOProfilePage({super.key});

  @override
  State<EditEOProfilePage> createState() => _EditEOProfilePageState();
}

class _EditEOProfilePageState extends State<EditEOProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _profilePictureController = TextEditingController();

  String? _baseLocation;
  bool _isLoading = true;

  final List<String> locations = [
    'Jakarta Barat',
    'Jakarta Pusat',
    'Jakarta Selatan',
    'Jakarta Timur',
    'Jakarta Utara',
    'Bekasi',
    'Bogor',
    'Depok',
    'Tangerang',
  ];

  @override
  void initState() {
    super.initState();

    _profilePictureController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfile();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _profilePictureController.dispose();
    super.dispose();
  }

  // =====================
  // API
  // =====================

  Future<void> _fetchProfile() async {
    final request = context.read<CookieRequest>();

    final response = await safeApiCall(
      context: context,
      call: () => request.get(ApiConfig.eventOrganizerProfile()),
      errorMessage: 'Gagal memuat profil. Periksa koneksi internet Anda.',
      onRetry: _fetchProfile,
    );

    if (!mounted || response == null) return;

    final data =
        response is Map && response.containsKey('data') ? response['data'] : response;

    setState(() {
      _usernameController.text = data['username'] ?? '';
      _profilePictureController.text = data['profile_picture'] ?? '';
      _baseLocation = data['base_location']; // ⬅️ SAMA PERSIS DENGAN DETAIL EVENT
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final request = context.read<CookieRequest>();
    setState(() => _isLoading = true);

    final response = await safeApiCall(
      context: context,
      call: () => request.post(
        ApiConfig.editEOProfile(),
        {
          'username': _usernameController.text,
          'profile_picture': _profilePictureController.text,
          'base_location': _baseLocation,
        },
      ),
      errorMessage: 'Gagal menyimpan perubahan profil.',
      onRetry: _saveProfile,
    );

    if (!mounted || response == null) return;

    setState(() => _isLoading = false);

    if (response['success'] == true || response['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Gagal memperbarui profil'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =====================
  // UI
  // =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildForm(),
            ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edit Details',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            _buildAvatar(),
            const SizedBox(height: 20),

            _buildProfilePictureInput(),
            const SizedBox(height: 16),

            _buildUsernameInput(),
            const SizedBox(height: 16),

            _buildLocationDropdown(),
            const SizedBox(height: 32),

            _buildSaveButton(),
            const SizedBox(height: 12),

            _buildCancelButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: CircleAvatar(
        radius: 56,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: _profilePictureController.text.isNotEmpty
            ? NetworkImage(_profilePictureController.text)
            : null,
        child: _profilePictureController.text.isEmpty
            ? const Icon(Icons.person, size: 48, color: Colors.grey)
            : null,
      ),
    );
  }

  Widget _buildProfilePictureInput() {
    return TextFormField(
      controller: _profilePictureController,
      decoration: InputDecoration(
        labelText: 'Profile Picture URL',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.link),
      ),
    );
  }

  Widget _buildUsernameInput() {
    return TextFormField(
      controller: _usernameController,
      validator: (v) => v == null || v.isEmpty ? 'Username tidak boleh kosong' : null,
      decoration: InputDecoration(
        labelText: 'Username',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.person_outline),
      ),
    );
  }

  Widget _buildLocationDropdown() {
    return DropdownButtonFormField<String>(
      value: _baseLocation,
      decoration: InputDecoration(
        labelText: 'Location',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.map_outlined),
      ),
      items: locations
          .map(
            (loc) => DropdownMenuItem(
              value: loc,
              child: Text(loc[0].toUpperCase() + loc.substring(1)),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() => _baseLocation = value);
      },
      validator: (v) => v == null ? 'Pilih lokasi' : null,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D4ED8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _saveProfile,
        child: const Text(
          'Save Changes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    );
  }
}
