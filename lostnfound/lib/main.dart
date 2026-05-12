import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/core/router/app_router.dart';
import 'package:lostnfound/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,

    realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 2),
  );

  await initializeDateFormatting('id_ID', null);

  // runApp(const MyApp());
  runApp(const ProviderScope(child: LostFoundApp()));
}

final supabase = Supabase.instance.client;

class LostFoundApp extends ConsumerWidget {
  const LostFoundApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Lost & Found',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
