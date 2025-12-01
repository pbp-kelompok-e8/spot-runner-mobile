import 'package:flutter/material.dart';
import 'package:spot_runner_mobile/features/auth/screens/login.dart';
import 'package:spot_runner_mobile/features/event/screens/editevent_form.dart';
import 'package:spot_runner_mobile/features/event/screens/event_form.dart';
import 'package:spot_runner_mobile/core/screens/menu.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TempTestPage(),
    );
  }
}

class TempTestPage extends StatelessWidget {
  const TempTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> mockEventData = {
      "id": "0144a7b9-cb16-4c6f-b660-becec343f797", 
      "name": "Lari Pagi Dummy",
      "description": "Ini adalah deskripsi event yang pura-puranya diambil dari API.",
      "location": "jakarta_selatan",
      "image": "",
      "image2": "",
      "image3": "",
      "contact": "08123456789",
      "capacity": 100,
      "coin": 500,
      // Pastikan format tanggal ISO String valid
      "event_date": DateTime.now().add(const Duration(days: 10)).toIso8601String(),
      "regist_deadline": DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      "event_categories": ["5k", "fun_run"] 
    };

    return Scaffold(
      appBar: AppBar(title: const Text("Halaman Testing")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TOMBOL KE CREATE
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventFormPage()),
                );
              },
              child: const Text("Test CREATE Event"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditEventFormPage(event: mockEventData),
                  ),
                );
              },
              child: const Text("Test EDIT Event (ID: 1)"),
            ),
          ],
        ),
      ),
    );
  }
}