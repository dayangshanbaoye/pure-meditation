import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'services/storage_service.dart';
import 'services/timer_service.dart';
import 'services/audio_handler.dart';
import 'services/local_music_service.dart';
import 'providers/meditation_provider.dart';
import 'providers/timer_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en', null);
  
  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final timerService = TimerService(storageService);
  
  // Initialize Audio Service
  final audioHandler = await initAudioService();

  // Initialize Local Music Service
  final localMusicService = LocalMusicService();
  await localMusicService.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MeditationProvider(storageService)..loadData()),
        ChangeNotifierProvider(create: (_) => TimerProvider(timerService)..init()),
        Provider<AudioPlayerHandler>.value(value: audioHandler as AudioPlayerHandler),
        ChangeNotifierProvider<LocalMusicService>.value(value: localMusicService),
      ],
      child: const PureMeditationApp(),
    ),
  );
}

class PureMeditationApp extends StatelessWidget {
  const PureMeditationApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pure Meditation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}
