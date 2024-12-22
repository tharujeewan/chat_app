import 'package:chat_app/Home_Screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase initialization
  final user = FirebaseAuth.instance.currentUser; // Check if user is logged in

  runApp(MyApp(user: user)); // Pass the user status to MyApp
}

class MyApp extends StatelessWidget {
  final User? user;
  const MyApp({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute:
          user != null ? '/home' : '/login', // Navigate based on user state
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => HomeScreen(user: user), // Pass user to HomeScreen
      },
    );
  }
}
