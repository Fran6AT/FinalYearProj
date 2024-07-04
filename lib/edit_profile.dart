import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmEmailController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final User? currentUser = FirebaseAuth.instance.currentUser;

  void _updateProfile() async {
    if (_emailController.text.trim() != currentUser?.email ||
        _passwordController.text.trim().isNotEmpty &&
            _passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please confirm your existing email and password correctly'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      if (_emailController.text.trim() != currentUser?.email) {
        await currentUser?.updateEmail(_emailController.text.trim());
      }

      if (_usernameController.text.trim() != currentUser?.displayName) {
        await currentUser?.updateDisplayName(_usernameController.text.trim());
      }

      if (_passwordController.text.trim().isNotEmpty &&
          _passwordController.text.trim() == _confirmPasswordController.text.trim()) {
        await currentUser?.updatePassword(_passwordController.text.trim());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'New Email'),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _confirmEmailController,
              decoration: InputDecoration(labelText: 'Confirm Email'),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
