import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';

class EditEOProfilePage extends StatefulWidget {
  const EditEOProfilePage({super.key});

  @override
  State<EditEOProfilePage> createState() => _EditEOProfilePageState();
}

class _EditEOProfilePageState extends State<EditEOProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _username = TextEditingController();
  final _profilePicture = TextEditingController();
  String? _baseLocation;

  bool _loading = true;


  final List<String> locations = [
    'jakarta',
    'surabaya',
    'bandung',
    'medan',
    'semarang',
    'makassar',
    'palembang',
    'denpasar',
    'yogyakarta',
    'surakarta',
    'malang',
    'pekanbaru',
    'depok',
  ];

  @override
  void initState() {
    super.initState();
    // Listener agar gambar berubah real-time saat link diketik
    _profilePicture.addListener(() {
      setState(() {});
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _username.dispose();
    _profilePicture.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    final request = context.read<CookieRequest>();
    try {
      final resp = await request.get(ApiConfig.eventOrganizerProfile());
      
      // DEBUG: Cek isi respon di terminal (Run tab)
      print("Response from server: $resp"); 

      if (!mounted) return;

      setState(() {
        // PERBAIKAN 2: Akses ke dalam key ['data'] jika ada
        // Logika: Cek apakah ada key 'data', jika tidak ada, coba ambil langsung dari resp
        final userData = (resp is Map && resp.containsKey('data')) ? resp['data'] : resp;

        if (userData != null) {
          _username.text = userData['username'] ?? '';
          _profilePicture.text = userData['profile_picture'] ?? '';
          
          // Handle Location (Case insensitive matching)
          String? locFromServer = userData['base_location'];
          if (locFromServer != null) {
            // Cari lokasi di list yang cocok (ignore case)
            try {
              _baseLocation = locations.firstWhere(
                (loc) => loc.toLowerCase() == locFromServer.toLowerCase()
              );
            } catch (e) {
              // Jika lokasi dari server tidak ada di list dropdown, set null atau default
              _baseLocation = null;
            }
          }
        }
        _loading = false;
      });
    } catch (e) {
      print("Error fetching profile: $e");
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    }
  }

  Future<void> _confirmSave() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Simpan Perubahan'),
        content: const Text(
            'Apakah Anda yakin ingin menyimpan perubahan profil ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _save();
    }
  }

  Future<void> _save() async {
    final request = context.read<CookieRequest>();
    setState(() => _loading = true);

    try {
      final resp = await request.post(ApiConfig.editEOProfile(), {
        'username': _username.text,
        'profile_picture': _profilePicture.text,
        'base_location': _baseLocation ?? '',
      });

      if (!mounted) return;

      if (resp['status'] == 'success' || resp['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!')),
        );
        Navigator.pop(context, true); // Kembali ke halaman profil
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp['message'] ?? 'Gagal memperbarui profil')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1D4ED8);
    const Color bgGrey = Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Text(
          'Edit Profile', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
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
                              "Edit Details",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 1. Profile Picture Preview
                            Center(
                              child: CircleAvatar(
                                radius: 56,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _profilePicture.text.isNotEmpty
                                    ? NetworkImage(_profilePicture.text)
                                    : null,
                                child: _profilePicture.text.isEmpty
                                    ? const Icon(Icons.person,
                                        size: 48, color: Colors.grey)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 2. Input URL Foto
                            TextFormField(
                              controller: _profilePicture,
                              decoration: InputDecoration(
                                labelText: 'Profile Picture URL',
                                hintText: 'https://example.com/image.jpg',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.link),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 3. Input Username
                            TextFormField(
                              controller: _username,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Username tidak boleh kosong'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // 4. Dropdown Location
                            DropdownButtonFormField<String>(
                              value: _baseLocation,
                              decoration: InputDecoration(
                                labelText: 'Location',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.map_outlined),
                              ),
                              items: locations.map((l) {
                                return DropdownMenuItem(
                                  value: l,
                                  child: Text(l.capitalize()),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _baseLocation = v),
                              validator: (v) => v == null ? 'Pilih lokasi' : null,
                            ),
                            
                            const SizedBox(height: 32),

                            // Save Button
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _confirmSave,
                                child: const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 12),

                            // Cancel Button
                            SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade400),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

extension StringCap on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}