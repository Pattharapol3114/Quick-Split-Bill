import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:quick_split_bill/screens/auth_landing_screen.dart';
import 'package:quick_split_bill/screens/group_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const scaffoldBg = Color(0xFFFAF8F5);
    const primaryGreen = Color(0xFF8A9A5B);
    const accentTerracotta = Color(0xFFD4A373);
    const textEarth = Color(0xFF4A4A4A);

    return MaterialApp(
      title: 'Quick Split Bill',
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: scaffoldBg,
        colorScheme: const ColorScheme.light(
          primary: primaryGreen,
          secondary: accentTerracotta,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: textEarth,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: textEarth,
          displayColor: textEarth,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: scaffoldBg,
          foregroundColor: textEarth,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textEarth,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: textEarth),
          actionsIconTheme: IconThemeData(color: textEarth),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1.2,
          shadowColor: const Color(0x1A4A4A4A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: textEarth.withValues(alpha: 0.14),
          thickness: 0.8,
          space: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(color: textEarth.withValues(alpha: 0.82)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: textEarth.withValues(alpha: 0.18)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: textEarth.withValues(alpha: 0.18)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: primaryGreen, width: 1.3),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        listTileTheme: ListTileThemeData(
          iconColor: textEarth,
          textColor: textEarth,
          subtitleTextStyle: TextStyle(
            color: textEarth.withValues(alpha: 0.68),
            fontSize: 13,
          ),
        ),
      ),
      home: const AppRoot(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _isGuestMode = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final currentUser = snapshot.data;

        if (currentUser != null) {
          return GroupManagementScreen(
            isGuestMode: false,
            onSignOutOrExit: () async {
              await FirebaseAuth.instance.signOut();
            },
          );
        }

        if (_isGuestMode) {
          return GroupManagementScreen(
            isGuestMode: true,
            onSignOutOrExit: () {
              setState(() {
                _isGuestMode = false;
              });
            },
          );
        }

        return AuthLandingScreen(
          onContinueAsGuest: () {
            setState(() {
              _isGuestMode = true;
            });
          },
        );
      },
    );
  }
}
