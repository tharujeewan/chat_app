import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String uid; // Sender's user ID
  final String recipientEmail; // Recipient's email address
  final String recipientName; // Recipient's name

  const ChatScreen({
    Key? key,
    required this.uid,
    required this.recipientEmail,
    required this.recipientName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final CollectionReference _messagesCollection =
      FirebaseFirestore.instance.collection('messages');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _currentUserEmail;
  List<String> _messageQueue = [];
  bool _isSending = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  void _fetchCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserEmail = user.email;
      });
    }
  }

  String _getConversationId(String senderEmail, String recipientEmail) {
    List<String> users = [senderEmail, recipientEmail];
    users.sort();
    return users.join('_');
  }

  void _sendMessage() async {
    if (_currentUserEmail == null) {
      print(
          'User is not logged in'); // Debugging: Check if the user is logged in
      return;
    }
    if (_messageController.text.trim().isNotEmpty) {
      String message = _messageController.text.trim();
      final conversationId =
          _getConversationId(_currentUserEmail!, widget.recipientEmail);

      final messageData = {
        'text': message,
        'sender': _currentUserEmail,
        'recipient': widget.recipientEmail,
        'conversationId': conversationId,
        'timestamp': FieldValue.serverTimestamp(),
      };

      print(
          "Sending message: $messageData"); // Debugging line to ensure correct data

      setState(() => _isSending = true);

      try {
        // Log Firestore collection and document path before attempting to add
        print("Attempting to send message to Firestore collection: 'messages'");

        // Attempt to add the message to Firestore
        await _messagesCollection.add(messageData);

        print("Message sent successfully.");
        _scrollToBottom(); // Scroll to the latest message
      } catch (e) {
        print(
            "Error sending message: $e"); // Log any error that occurs during Firestore write
      } finally {
        setState(() {
          _isSending = false;
        });
      }
    } else {
      print("Message is empty."); // Log if the message is empty and not sent
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('conversationId',
                      isEqualTo: _getConversationId(
                          _currentUserEmail ?? '', widget.recipientEmail))
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet."));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>;
                    final isSender = message['sender'] == _currentUserEmail;

                    return Align(
                      alignment: isSender
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 10.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isSender ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          message['text'] ?? '',
                          style: TextStyle(
                            color: isSender ? Colors.white : Colors.black,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${widget.recipientName} is typing...',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (text) {
                      setState(() {
                        _isTyping = text.isNotEmpty;
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
