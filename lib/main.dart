import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

// AUTH
import 'features/auth/login/login_controller.dart';
import 'features/auth/login/login_screen.dart';
import 'features/auth/signup/signup_screen.dart';

// NAVIGATION
import 'features/navigation/main_navigation.dart';

// POST
import 'features/post/create/create_post_screen.dart';

// SEARCH
import 'features/search/search_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const E6App());
}

class E6App extends StatelessWidget {
  const E6App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => LoginController())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Piccture',

        //
        // -------- THEME --------
        //
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFF5EDE3),
          primaryColor: const Color(0xFFC56A45),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: const Color(0xFF6C7A4C),
          ),
          fontFamily: "Roboto",
        ),

        //
        // -------- ROUTES --------
        //
        initialRoute: "/login",
        routes: {
          "/login": (context) => const LoginScreen(),
          "/signup": (context) => SignupScreen(),
          "/home": (context) => const MainNavigation(),
          "/create-post": (context) => const CreatePostScreen(),
          "/search": (context) => const SearchScreen(),
        },
      ),
    );
  }
}
