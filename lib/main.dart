import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/home_shell.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );
  runApp(const CheckMeApp());
}

class CheckMeApp extends StatelessWidget {
  final StorageService? storageService;

  const CheckMeApp({super.key, this.storageService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CheckMe',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: HomeShell(storageService: storageService),
    );
  }
}
