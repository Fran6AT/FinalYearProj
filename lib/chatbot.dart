import 'package:flutter/material.dart';
import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({Key? key, required List<Map<String, dynamic>> messages}) : super(key: key);

  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  late DialogFlowtter dialogFlowtter;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController(); // Added search controller
  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> searchResults = []; // Added list for search results
  final DatabaseReference chatRef = FirebaseDatabase.instance.reference().child('chat_history');

  @override
  void initState() {
    super.initState();
    DialogFlowtter.fromFile().then((instance) => dialogFlowtter = instance);
    fetchChatHistory(); // Fetch chat history when screen initializes
  }

  void fetchChatHistory() {
    chatRef.once().then((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data != null) {
        List<Map<String, dynamic>> tempMessages = [];
        (data as Map).forEach((key, value) {
          tempMessages.add({
            'message': Message(text: DialogText(text: [value['text']])),
            'isUserMessage': value['isUserMessage'],
          });
        });
        setState(() {
          messages = List.from(tempMessages.reversed); // Reverse the order to display correctly
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ChatBot'),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade900,
        actions: [
          IconButton(
            onPressed: () {
              searchMessages(_searchController.text); // Perform search when search icon is pressed
            },
            icon: Icon(Icons.search),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade700,
              Colors.indigo.shade900,
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  // Clear search results when search text changes
                  setState(() {
                    searchResults.clear();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _searchController.clear(); // Clear search text when clear icon is pressed
                      setState(() {
                        searchResults.clear();
                      });
                    },
                    icon: Icon(Icons.clear),
                  ),
                ),
              ),
            ),
            Expanded(child: MessagesScreen(messages: searchResults.isEmpty ? messages : searchResults)), // Show search results if available, otherwise show all messages
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  IconButton(
                    onPressed: () {
                      sendMessage(_controller.text);
                      _controller.clear();
                    },
                    icon: Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  sendMessage(String text) async {
    if (text.isEmpty) {
      print('Message is empty');
    } else {
      setState(() {
        addMessage(Message(text: DialogText(text: [text])), true);
      });

      DetectIntentResponse response = await dialogFlowtter.detectIntent(
          queryInput: QueryInput(text: TextInput(text: text)));
      if (response.message == null) return;
      setState(() {
        addMessage(response.message!, false); // Add bot response with isUserMessage = false
      });

      saveMessageToFirebase(text, true); // Save the user's message to Firebase with isUserMessage = true
      saveMessageToFirebase(response.message!.text!.text![0], false); // Save the bot's response to Firebase with isUserMessage = false
    }
  }

  addMessage(Message message, bool isUserMessage) {
    setState(() {
      messages.add({'message': message, 'isUserMessage': isUserMessage});
    });
  }

  saveMessageToFirebase(String message, bool isUserMessage) {
    chatRef.push().set({
      'text': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'isUserMessage': isUserMessage,
    });
  }

  searchMessages(String query) {
    if (query.isEmpty) return;

    final List<Map<String, dynamic>> searchResultsTemp = [];

    for (var message in messages) {
      final messageContent = message['message'].text.text[0].toLowerCase();
      if (messageContent.contains(query.toLowerCase())) {
        searchResultsTemp.add(message);
      }
    }

    setState(() {
      searchResults.clear();
      searchResults.addAll(searchResultsTemp);
    });
  }
}

class MessagesScreen extends StatefulWidget {
  final List messages;
  const MessagesScreen({Key? key, required this.messages}) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    return ListView.builder(
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final isUserMessage = widget.messages[index]['isUserMessage'];
        final messageContent = widget.messages[index]['message'].text.text[0];

        return Container(
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: isUserMessage ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              messageContent,
              style: TextStyle(
                color: isUserMessage ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ChatBotScreen(messages: []),
  ));
}
