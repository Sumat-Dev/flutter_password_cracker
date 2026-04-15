import 'package:flutter/material.dart';
import 'package:flutter_password_cracker/bridge/native/frb_generated.dart';
import 'package:flutter_password_cracker/screens/crack_screen.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Password Cracker',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7F77DD),
          secondary: Color(0xFF5DCAA5),
        ),
      ),
      home: CrackScreen(),
    );
  }
}


