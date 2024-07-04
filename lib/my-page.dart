import 'package:flutter/material.dart';

import 'edit_profile.dart';

class MyPageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle,
            size: 80,
            color: Colors.blue,
          ),
          SizedBox(height: 20),
          Text(
            'Welcome User!',
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to the EditProfileScreen
              Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen()));
            },
            icon: Icon(Icons.edit),
            label: Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              primary: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Implement the action for Button 2 (Settings and Preferences)
              // For example, navigate to a settings screen
              Navigator.pushNamed(context, '/settings');
            },
            icon: Icon(Icons.settings),
            label: Text('Settings'),
            style: ElevatedButton.styleFrom(
              primary: Colors.orange,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
