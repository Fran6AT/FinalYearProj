import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:face_rec_new/previous_res.dart'; // Import your PreviousResultsScreen file

class ResultsScreen extends StatelessWidget {
  final List<String> emotions;
  final String dominantEmotion;

  const ResultsScreen({Key? key, required this.emotions, required this.dominantEmotion, required List<String> trackedEmotions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Save new result to the database
    _saveResult();

    return Scaffold(
      appBar: AppBar(
        title: Text('Emotion Prediction'),
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Most Dominant Emotion:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 10),
            Text(
              dominantEmotion,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Tracking Time:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 10),
            Text(
              _getCurrentDateTime(),
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Your past results:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: _buildResultsList(context),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentDateTime() {
    DateTime now = DateTime.now();
    return '${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}:${now.second}';
  }

  void _saveResult() {
    // Get the current user's UID
    String? userUid = FirebaseAuth.instance.currentUser?.uid;

    if (userUid != null) {
      // Write the result to Firebase Realtime Database under the user's node
      DatabaseReference dbRef = FirebaseDatabase.instance.reference().child('emotion_results').child(userUid);
      String trackingTime = _getCurrentDateTime();

      dbRef.push().set({
        'dominant_emotion': dominantEmotion,
        'tracking_time': trackingTime,
      });
    }
  }

  Widget _buildResultsList(BuildContext context) {
    return StreamBuilder(
      stream: _getResultsStream(),
      builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
        if (snapshot.hasData && snapshot.data!.value != null) {
          final Map<dynamic, dynamic> resultsMap = snapshot.data!.value as Map<dynamic, dynamic>;
          final List<Widget> resultWidgets = [];

          // Add the most recent 5 results
          int count = 0;
          resultsMap.entries.forEach((entry) {
            if (count < 5) {
              final Map<String, dynamic> resultData = Map<String, dynamic>.from(entry.value);

              // Parse tracking time with error handling
              DateTime? trackingTime;
              try {
                trackingTime = DateTime.parse(resultData['tracking_time']);
              } catch (e) {
                print('Error parsing tracking time: $e');
              }

              // Check if the result is new
              final bool isNewResult = trackingTime != null && trackingTime.isAfter(DateTime.now().subtract(Duration(minutes: 5)));

              resultWidgets.add(ListTile(
                title: Text('Dominant Emotion: ${resultData['dominant_emotion']}'),
                subtitle: Text('Tracking Time: ${resultData['tracking_time']}'),
                trailing: isNewResult ? Icon(Icons.new_releases, color: Colors.green) : SizedBox(),
              ));
              count++;
            }
          });

          // Add "See more" button
          resultWidgets.add(
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PreviousResultsScreen()),
                );
              },
              child: Text('See more'),
            ),
          );

          return ListView(
            children: resultWidgets,
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Stream<DataSnapshot> _getResultsStream() {
    String? userUid = FirebaseAuth.instance.currentUser?.uid;
    if (userUid != null) {
      DatabaseReference dbRef = FirebaseDatabase.instance.reference().child('emotion_results').child(userUid);
      return dbRef.onValue.map((event) => event.snapshot);
    } else {
      return Stream<DataSnapshot>.empty();
    }
  }
}
