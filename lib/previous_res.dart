import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PreviousResultsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Previous Results'),
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
      ),
    );
  }

  Widget _buildResultsList(BuildContext context) {
    return StreamBuilder(
      stream: _getResultsStream(),
      builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
        if (snapshot.hasData && snapshot.data!.value != null) {
          final Map<dynamic, dynamic> resultsMap = snapshot.data!.value as Map<dynamic, dynamic>;
          final List<Widget> resultWidgets = [];

          // Add all results
          resultsMap.entries.forEach((entry) {
            final Map<String, dynamic> resultData = Map<String, dynamic>.from(entry.value);

            // Parse tracking time with error handling
            DateTime? trackingTime;
            try {
              trackingTime = DateTime.parse(resultData['tracking_time']);
            } catch (e) {
              print('Error parsing tracking time: $e');
            }

            resultWidgets.add(ListTile(
              title: Text('Dominant Emotion: ${resultData['dominant_emotion']}'),
              subtitle: Text('Tracking Time: ${resultData['tracking_time']}'),
            ));
          });

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
