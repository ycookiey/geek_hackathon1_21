import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:geek_hackathon1_21/env.dart';
import 'package:geek_hackathon1_21/services/location_service.dart';
import 'package:geek_hackathon1_21/views/map_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocationService.requestPermission();

  await Supabase.initialize(
    url: 'https://ifuswhoatzauxusfgtyo.supabase.co',
    anonKey: Env.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Maps',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MapView(),
    );
  }
}
