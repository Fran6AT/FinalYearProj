import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'emotion_track.dart';

class SavedDiaryScreen extends StatefulWidget {
  @override
  _SavedDiaryScreenState createState() => _SavedDiaryScreenState();
}

class _SavedDiaryScreenState extends State<SavedDiaryScreen> {
  final DatabaseReference diaryRef = FirebaseDatabase.instance.reference().child('diaries');
  final List<String> savedDiaries = []; // List of saved diary entries

  @override
  void initState() {
    super.initState();
    fetchSavedDiaries();
  }

  void fetchSavedDiaries() {
    diaryRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null) {
        setState(() {
          savedDiaries.clear();
          (data as Map).forEach((key, value) {
            savedDiaries.add(value['text']);
          });
        });
      }
    });
  }

  Future<Map<String, dynamic>> analyzeSentiment(String text) async {
    final String apiKey =
        'AIzaSyANgX2DpkkDqsg6c-93D4xHY-MoPWU61bo'; // Replace with your actual API key
    final url =
        'https://language.googleapis.com/v1/documents:analyzeSentiment?key=$apiKey';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'document': {'type': 'PLAIN_TEXT', 'content': text},
        'encodingType': 'UTF8',
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final score = data['documentSentiment']['score'];
      final magnitude = data['documentSentiment']['magnitude'];

      return {
        'score': score,
        'magnitude': magnitude,
      };
    } else {
      throw Exception('Failed to analyze sentiment');
    }
  }

  void saveDiary(String text) {
    diaryRef.push().set({'text': text, 'timestamp': DateTime.now().millisecondsSinceEpoch});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Diaries'),
      ),
      body: savedDiaries.isEmpty
          ? Center(
              child: Text(
                'No saved diaries yet',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: savedDiaries.length,
              itemBuilder: (context, index) {
                String title = savedDiaries[index].split(' ').take(6).join(' ');
                String diaryText = savedDiaries[index];
                return FutureBuilder<Map<String, dynamic>>(
                  future: analyzeSentiment(diaryText),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      double score = snapshot.data!['score'];
                      String emoji;
                      if (score > 0.2) {
                        emoji = '😊';
                      } else if (score < -0.2) {
                        emoji = '😞';
                      } else {
                        emoji = '😐';
                      }
                      return ListTile(
                        leading: Text(emoji, style: TextStyle(fontSize: 24)),
                        title: Text(title),
                        subtitle: Text(
                          '${DateTime.now().toString().substring(11, 16)}', // Extracts time (HH:MM)
                          style: TextStyle(color: Colors.grey),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DiaryDetailView(
                                initialDiaryText: diaryText,
                                onUpdate: (updatedText) {
                                  saveDiary(updatedText); // Save updated text to Firebase
                                },
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}

class DiaryDetailView extends StatefulWidget {
  final String initialDiaryText; // The initial text of the diary entry
  final Function(String) onUpdate; // Callback function to update the diary text

  const DiaryDetailView({Key? key, required this.initialDiaryText, required this.onUpdate})
      : super(key: key);

  @override
  _DiaryDetailViewState createState() => _DiaryDetailViewState();
}

class _DiaryDetailViewState extends State<DiaryDetailView> {
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: widget.initialDiaryText);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diary Detail'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              String updatedText = _textEditingController.text;
              widget.onUpdate(updatedText);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _textEditingController,
          maxLines: null, // Allow multiline editing
          decoration: InputDecoration(
            hintText: 'Enter your diary entry',
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: EmotionTrackingScreen(
      onBackPressed: () {
        // Handle back press from EmotionTrackingScreen
        // For example, pop the screen or show an alert dialog
      },
    ),
  ));
}
