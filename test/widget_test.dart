import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/main.dart'; // Adjust the import according to your file structure
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  testWidgets('Login Screen Widget Test', (WidgetTester tester) async {
    // Mocking Firebase user to simulate a logged-in state
    final mockUser = FirebaseAuth.instance.currentUser;

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(user: mockUser));

    // Verify that the app is showing the login screen if no user is logged in
    expect(find.text('Login'), findsOneWidget);

    // Add more widget tests here, such as tapping buttons or checking content visibility
  });
}
