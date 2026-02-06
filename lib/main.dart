import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eco_tisb/utils/colors.dart';
import 'package:eco_tisb/screens/welcome_screen.dart';
import 'package:eco_tisb/screens/marketplace_screen.dart';
import 'package:eco_tisb/screens/list_item_screen.dart';
import 'package:eco_tisb/screens/chat_screen.dart';
import 'package:eco_tisb/screens/chat_list_screen.dart';
import 'package:eco_tisb/screens/profile_screen.dart';
import 'package:eco_tisb/screens/lost_found_screen.dart';
import 'package:eco_tisb/screens/report_item_screen.dart';

import 'dart:io';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


void _logDebug(String location, String message, {Map<String, dynamic>? data, String hypothesisId = ''}) {
  try {
    final logFile = File(r'd:\CODES\Flutter\Code\eco_tisb\.cursor\debug.log');
    final logEntry = {
      'sessionId': 'debug-session',
      'runId': 'run1',
      'hypothesisId': hypothesisId,
      'location': location,
      'message': message,
      'data': data ?? {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    logFile.writeAsStringSync('${jsonEncode(logEntry)}\n', mode: FileMode.append);
  } catch (e) {
    // Silently fail if logging doesn't work
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  _logDebug('main.dart:19', 'Starting app initialization', hypothesisId: 'A');
  


  
  _logDebug('main.dart:24', 'Attempting to load .env file', hypothesisId: 'A');
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    
    _logDebug('main.dart:27', 'Failed to load .env file', data: {
      'error': e.toString(),
    }, hypothesisId: 'A');
    
    debugPrint('ERROR: Failed to load .env file. Make sure .env exists in the project root.');
    debugPrint('Create a .env file with: SUPABASE_URL=your_url and SUPABASE_ANON_KEY=your_key');
    rethrow;
  }

  
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];
  _logDebug('main.dart:36', 'After .env load - checking values', data: {
    'SUPABASE_URL_exists': supabaseUrl != null,
    'SUPABASE_URL_length': supabaseUrl?.length ?? 0,
    'SUPABASE_URL_value': supabaseUrl ?? 'null',
    'SUPABASE_URL_is_placeholder': supabaseUrl?.contains('YOUR_SUPABASE_URL') ?? false,
    'SUPABASE_ANON_KEY_exists': supabaseKey != null,
    'SUPABASE_ANON_KEY_length': supabaseKey?.length ?? 0,
    'SUPABASE_ANON_KEY_preview': supabaseKey != null ? '${supabaseKey.substring(0, supabaseKey.length > 10 ? 10 : supabaseKey.length)}...' : 'null',
    'SUPABASE_ANON_KEY_is_placeholder': supabaseKey?.contains('YOUR_SUPABASE') ?? false,
  }, hypothesisId: 'B,C,D');
  


  if (supabaseUrl == null || supabaseUrl.isEmpty || supabaseUrl.contains('YOUR_SUPABASE_URL')) {
    
    _logDebug('main.dart:50', 'Invalid SUPABASE_URL', hypothesisId: 'B');
    
    throw Exception(
        'SUPABASE_URL is not configured properly in .env file.\n'
            'Please create a .env file in the project root with:\n'
            'SUPABASE_URL=https://your-project.supabase.co\n'
            'SUPABASE_ANON_KEY=your-anon-key\n\n'
            'Get these values from: https://app.supabase.com/project/_/settings/api'
    );
  }


  if (supabaseUrl.contains('.supabase.com') && !supabaseUrl.contains('.supabase.co')) {
    
    _logDebug('main.dart:90', 'URL has .com instead of .co', data: {
      'url': supabaseUrl,
    }, hypothesisId: 'B');
    
    throw Exception(
        'SUPABASE_URL appears to use .com instead of .co\n'
            'Your URL: $supabaseUrl\n'
            'Supabase URLs should end with .supabase.co (not .com)\n'
            'Please update your .env file with the correct URL ending in .supabase.co'
    );
  }

  if (supabaseKey == null || supabaseKey.isEmpty || supabaseKey.contains('YOUR_SUPABASE')) {
    
    _logDebug('main.dart:60', 'Invalid SUPABASE_ANON_KEY', hypothesisId: 'B');
    
    throw Exception(
        'SUPABASE_ANON_KEY is not configured properly in .env file.\n'
            'Please create a .env file in the project root with:\n'
            'SUPABASE_URL=https://your-project.supabase.co\n'
            'SUPABASE_ANON_KEY=your-anon-key\n\n'
            'Get these values from: https://app.supabase.com/project/_/settings/api'
    );
  }


  
  _logDebug('main.dart:104', 'Before Supabase.initialize', data: {
    'url_being_used': supabaseUrl,
    'url_ends_with_co': supabaseUrl.endsWith('.supabase.co'),
    'url_ends_with_com': supabaseUrl.endsWith('.supabase.com'),
  }, hypothesisId: 'D');
  
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );

    
    _logDebug('main.dart:79', 'After Supabase.initialize', data: {
      'client_initialized': true,
      'client_auth_available': true,
    }, hypothesisId: 'D,E');
    
  } catch (e) {
    
    _logDebug('main.dart:86', 'Supabase.initialize failed', data: {
      'error': e.toString(),
    }, hypothesisId: 'D');
    
    debugPrint('ERROR: Failed to initialize Supabase: $e');
    debugPrint('Please verify your SUPABASE_URL and SUPABASE_ANON_KEY are correct in .env');
    rethrow;
  }

  runApp(const EcoTISBApp());
}

class EcoTISBApp extends StatelessWidget {
  const EcoTISBApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TISB Swap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/marketplace': (context) => const MarketplaceScreen(),

        '/list-item': (context) => const ListItemScreen(),
        '/chat': (context) => const ChatScreen(),
        '/chat-list': (context) => const ChatListScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/lost-found': (context) => const LostFoundScreen(),
        '/report-item': (context) => const ReportItemScreen(),
      },
    );
  }
}
