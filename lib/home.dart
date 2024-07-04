import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'chatbot.dart'; // Import your ChatBotScreen file
import 'emotion_track.dart';
import 'my-page.dart';
import 'previous_res.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isTrackingEmotion = false;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // Add this key

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Use the GlobalKey for the Scaffold
      appBar: _selectedIndex == 0 ? AppBar(title: Text('Home')) : null, // Add the AppBar for the home screen
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Mind Mentor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                _navigateToScreen(0);
              },
            ),
            ListTile(
              leading: Icon(Icons.chat),
              title: Text('Chat'),
              onTap: () {
                _navigateToScreen(1);
              },
            ),
            ListTile(
              leading: Icon(Icons.track_changes),
              title: Text('Track Changes'),
              onTap: () {
                _navigateToScreen(2);
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('My Page'),
              onTap: () {
                _navigateToScreen(3);
              },
            ),
            ListTile(
              leading: Icon(Icons.history), // Add icon for history or previous results
              title: Text('Previous Results'), // Change title accordingly
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(context, MaterialPageRoute(builder: (context) => PreviousResultsScreen())); // Navigate to previous results screen
              },
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 500),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: _isTrackingEmotion
            ? EmotionTrackingScreen(
                onBackPressed: () {
                  setState(() {
                    _isTrackingEmotion = false;
                  });
                },
              )
            : _getCurrentScreen(),
      ),
    );
  }

  void _navigateToScreen(int index) {
    setState(() {
      _selectedIndex = index;
      _isTrackingEmotion = index == 2; // Enable emotion tracking only for Track Changes screen
      Navigator.pop(context); // Close the drawer
    });
  }

  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MotivationalQuoteWidget(text: '"The only way to do great work is to love what you do." - Steve Jobs'),
              SizedBox(height: 10),
              MotivationalQuoteWidget(text: '"The future belongs to those who believe in the beauty of their dreams." - Eleanor Roosevelt'),
              SizedBox(height: 10),
              MotivationalQuoteWidget(text: '"Success is not final, failure is not fatal: It is the courage to continue that counts." - Winston Churchill'),
              SizedBox(height: 10),
              MotivationalQuoteWidget(text: ' "You are never too old to set another goal or to dream a new dream." - C.S. Lewis'),
              SizedBox(height: 10),
              MotivationalQuoteWidget(text: ' If you are experiencing thoughts of self-harm or suicide, it is important to seek help immediately. You can contact a crisis hotline below for support.Ashanti Region 0322022323  0322025441'),
            ],
          ),
        );
      case 1:
        return ChatBotScreen(messages: [],); // Display ChatBotScreen directly
      case 2:
        return EmotionTrackingScreen(
          onBackPressed: () {
            setState(() {
              _isTrackingEmotion = false;
            });
          },
        );
      case 3:
        return MyPageScreen();
      default:
        return Center(child: Text('Home Screen Content'));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class MotivationalQuoteWidget extends StatelessWidget {
  final String text;

  const MotivationalQuoteWidget({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8, // Set the width to 80% of the screen width
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightBlueAccent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center, // Center align the text
      ),
    );
  }
}
