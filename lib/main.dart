import 'dart:math';

import 'package:flutter/material.dart';
import 'package:spot_runner_mobile/core/widgets/error_handler.dart';
import 'package:spot_runner_mobile/core/widgets/error_retry.dart';
import 'package:spot_runner_mobile/features/auth/screens/login.dart';
import 'package:spot_runner_mobile/features/event/screens/editevent_form.dart';
import 'package:spot_runner_mobile/features/event/screens/event_form.dart';
import 'package:spot_runner_mobile/core/screens/menu.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:spot_runner_mobile/features/event/screens/testpage.dart';
import 'package:spot_runner_mobile/features/auth/screens/login.dart';
import 'package:spot_runner_mobile/core/providers/user_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // <--- Ganti jadi MultiProvider
      providers: [
        Provider(
          create: (_) {
            CookieRequest request = CookieRequest();
            return request;
          },
        ),
        ChangeNotifierProvider(
          // <--- Tambahkan UserProvider
          create: (_) => UserProvider(),
        ),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: MaterialApp(
        title: 'Spot Runner',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.blue,
          ).copyWith(secondary: Colors.blueAccent[400]),
        ),
        builder: (context, child) {
          final connectivity = context.watch<ConnectivityProvider>();
          return Stack(
            children: [
              child!, 
              if (connectivity.hasError)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(
                      0.9,
                    ), 
                    child: Scaffold(
                      backgroundColor: Colors.transparent,
                      body: ErrorRetryWidget(
                        message: connectivity.errorMessage,
                        onRetry: () => connectivity.retry(),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        home: const LoginPage(),
      ),
    );
  }
}
