import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:spot_runner_mobile/main.dart';

class EventFormPage extends StatefulWidget {
  const EventFormPage({super.key});

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _eventName = "";
  String _description = "";
  int _totalParticipants = 0;
  String _location = "jakarta_barat";
  String _image = "";
  String _image2 = "";
  String _image3 = "";
  DateTime _eventDate = DateTime.now();
  DateTime _registDeadline = DateTime.now();
  String _contact = "";
  int _capacity = 0;
  int _coin = 0;

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
  @override
  Widget build(BuildContext context) {
    // final request = context.watch<CookieRequest>();
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Form Tambah Produk')),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      // drawer: LeftDrawer(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === Name ===
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: "Enter event name",
                    labelText: "Event Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  maxLength: 100,
                  onChanged: (String? value) {
                    setState(() {
                      _eventName = value!;
                    });
                  },
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Nama produk tidak boleh kosong!";
                    }
                    return null;
                  },
                ),
              ),
              // === Price ===
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: "Harga Produk",
                    labelText: "Harga Produk",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (String? value) {
                    setState(() {
                      _totalParticipants = int.tryParse(value ?? '') ?? 0;
                    });
                  },
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Harga produk tidak boleh kosong!";
                    }
                    final int? price = int.tryParse(value);
                    if (price == null) {
                      return "Harap masukkan angka yang valid.";
                    }
                    if (price < 0) {
                      return "Harga tidak boleh negatif!";
                    }
                    return null;
                  },
                ),
              ),
              // === Description ===
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Deskripsi Produk",
                    labelText: "Deskripsi Produk",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  maxLength: 1000,
                  onChanged: (String? value) {
                    setState(() {
                      _description = value!;
                    });
                  },
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Deskripsi tidak boleh kosong!";
                    }
                    return null;
                  },
                ),
              ),

              // === Category ===
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Kategori",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  value: _location,
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
                  onChanged: (String? newValue) {
                    setState(() {
                      _location = newValue!;
                    });
                  },
                ),
              ),

              // === Thumbnail URL ===
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: "URL Thumbnail (opsional)",
                    labelText: "URL Thumbnail",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  keyboardType: TextInputType.url,
                  onChanged: (String? value) {
                    setState(() {
                      _image = value ?? '';
                    });
                  },
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return null;
                    }
                    final Uri? uri = Uri.tryParse(value);
                    if (uri == null) {
                      return "Format URL tidak valid.";
                    }
                    if (!uri.hasScheme || !uri.hasAuthority) {
                      return "Masukkan URL lengkap (contoh: https://google.com)";
                    }
                    return null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: "URL Thumbnail (opsional)",
                    labelText: "URL Thumbnail",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  keyboardType: TextInputType.url,
                  onChanged: (String? value) {
                    setState(() {
                      _image2 = value ?? '';
                    });
                  },
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return null;
                    }
                    final Uri? uri = Uri.tryParse(value);
                    if (uri == null) {
                      return "Format URL tidak valid.";
                    }
                    if (!uri.hasScheme || !uri.hasAuthority) {
                      return "Masukkan URL lengkap (contoh: https://google.com)";
                    }
                    return null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: "URL Thumbnail (opsional)",
                    labelText: "URL Thumbnail",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  keyboardType: TextInputType.url,
                  onChanged: (String? value) {
                    setState(() {
                      _image3 = value ?? '';
                    });
                  },
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return null;
                    }
                    final Uri? uri = Uri.tryParse(value);
                    if (uri == null) {
                      return "Format URL tidak valid.";
                    }
                    if (!uri.hasScheme || !uri.hasAuthority) {
                      return "Masukkan URL lengkap (contoh: https://google.com)";
                    }
                    return null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ),

              // === Is Featured ===
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: SwitchListTile(
              //     title: const Text("Tandai sebagai Produk Unggulan"),
              //     value: _isFeatured,
              //     onChanged: (bool value) {
              //       setState(() {
              //         _isFeatured = value;
              //       });
              //     },
              //   ),
              // ),

              // === Tombol Simpan ===
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        Colors.blue,
                      ),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // TODO: Replace the URL with your app's URL
                        // To connect Android emulator with Django on localhost, use URL http://10.0.2.2/
                        // If you using chrome,  use URL http://localhost:8000

                        // final response = await request.postJson(
                        //   "http://localhost:8000/create-flutter/",
                        //   jsonEncode({
                        //     "name": _eventName,
                        //     "description": _description,
                        //     "price": _totalParticipants,
                        //     "thumbnail": _image,
                        //     "category": _location,
                        //   }),
                        // );
                        if (context.mounted) {
                          // if (response['status'] == 'success') {
                          //   ScaffoldMessenger.of(context).showSnackBar(
                          //     const SnackBar(
                          //       content: Text("Product successfully added!"),
                          //     ),
                          //   );
                          //   Navigator.pushReplacement(
                          //     context,
                          //     MaterialPageRoute(
                          //       builder: (context) => MyHomePage(title: 'Flutter Demo Home Page'),
                          //     ),
                          //   );
                          // } else {
                          //   ScaffoldMessenger.of(context).showSnackBar(
                          //     const SnackBar(
                          //       content: Text(
                          //         "Something went wrong, please try again.",
                          //       ),
                          //     ),
                          //   );
                          // }
                        }
                      }
                    },
                    child: const Text(
                      "Simpan",
                      style: TextStyle(color: Colors.white),
                    ),
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
