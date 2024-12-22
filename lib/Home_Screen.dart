import 'package:chat_app/Chat_Screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, User? user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String? _userEmail;
  String? _userName;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch current user details (email and name)
  void _fetchUserData() async {
    final user = _auth.currentUser;

    if (user != null) {
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        final userData = userDoc.data();

        setState(() {
          _userEmail = user.email;
          _userName = userData?['name'] ?? 'No Name Available';
        });
      } catch (e) {
        print("Error fetching user data: $e");
        setState(() {
          _userEmail = user.email;
          _userName = 'No Name Available';
        });
      }
    }
  }

  // Logout function
  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Search for users in Firestore
  void _searchUsers() async {
    setState(() {
      _isLoading = true;
    });

    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThan: query + 'z')
          .get();

      setState(() {
        _searchResults = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'email': data['email'] ?? 'No Email',
            'name': data['name'] ?? 'Unknown',
            'uid': doc.id, // Use document ID as UID
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching users: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Navigate to Chat Screen
  void _navigateToChatScreen(
      String uid, String recipientEmail, String recipientName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          uid: uid, // This is the document ID (unique user identifier)
          recipientEmail: recipientEmail,
          recipientName: recipientName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Screen"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                _userName ?? 'No Name Available',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(_userEmail ?? 'No Email'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.orange,
                child: Text(
                  _userName != null && _userName!.isNotEmpty
                      ? _userName![0].toUpperCase()
                      : 'U',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Field
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Users',
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => _searchUsers(),
            ),
            const SizedBox(height: 20),

            // Loading Indicator
            if (_isLoading) const Center(child: CircularProgressIndicator()),

            // Search Results
            if (_searchResults.isNotEmpty && !_isLoading)
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: GestureDetector(
                          onTap: () => _navigateToChatScreen(
                            result['uid'], // This is the Firestore document ID
                            result['email'],
                            result['name'],
                          ),
                          child: Text(
                            result['email'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        subtitle: Text('Name: ${result['name']}'),
                      ),
                    );
                  },
                ),
              )
            else if (_searchController.text.isNotEmpty && !_isLoading)
              const Text("No users found.")
            else
              const Text("Search for a user."),
          ],
        ),
      ),
    );
  }
}
