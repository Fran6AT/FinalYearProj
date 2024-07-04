import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'emotion_track.dart'; // Import the EmotionTrackScreen widget
import 'home.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late String _emailOrUsername, _password;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showPassword = false; // Add this variable to track password visibility

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Welcome Back',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      validator: (input) {
                        if (input == null || input.isEmpty) {
                          return 'Enter your email or username';
                        }
                        return null;
                      },
                      onSaved: (input) => _emailOrUsername = input!,
                      decoration: InputDecoration(
                        labelText: 'Email or Username',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      validator: (input) {
                        if (input == null || input.isEmpty) {
                          return 'Enter your password';
                        }
                        return null;
                      },
                      onSaved: (input) => _password = input!,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                          icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                        ),
                      ),
                      obscureText: !_showPassword, // Toggle password visibility
                    ),
                    SizedBox(height: 20),
                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: signIn,
                            child: Text('Log In'),
                          ),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignupScreen(),
                          ),
                        );
                      },
                      child: Text('Create an Account'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> signIn() async {
    final formState = _formKey.currentState;
    if (formState != null && formState.validate()) {
      formState.save();
      setState(() {
        _isLoading = true;
      });
      try {
        // Check if the input is a valid email format
        if (_emailOrUsername.contains('@')) {
          // Sign in using email
          UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailOrUsername,
            password: _password,
          );
          print('User signed in: ${userCredential.user!.uid}');
        } else {
          // Sign in using username (custom logic)
          // You need to implement your own logic for signing in with a username
          // This might involve querying a database to find the user by username
          // and then verifying the password
          print('Sign in with username is not implemented yet.');
        }
        // Navigate to the EmotionTrackScreen or HomeScreen based on the logic above
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } catch (e) {
        print('Error: $e');
        // Show error message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
