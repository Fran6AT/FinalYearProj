import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'ResultsScreen.dart';
import 'saved_diaries.dart';

class EmotionTrackingScreen extends StatefulWidget {
  final VoidCallback onBackPressed;

  const EmotionTrackingScreen({Key? key, required this.onBackPressed}) : super(key: key);

  @override
  _EmotionTrackingScreenState createState() => _EmotionTrackingScreenState();
}

class _EmotionTrackingScreenState extends State<EmotionTrackingScreen> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  TextEditingController diaryController = TextEditingController();
  List<CameraDescription>? cameras;
  String latestPrediction = '';
  List<String> trackedEmotions = [];
  bool isTracking = false;
  bool showStopButton = false;
  final DatabaseReference diaryRef = FirebaseDatabase.instance.reference().child('diaries');

  @override
  void initState() {
    super.initState();
    loadCameras();
    loadModel();
  }

  Future<void> loadCameras() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      CameraDescription? frontCamera;
      for (CameraDescription camera in cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }
      if (frontCamera != null) {
        cameraController = CameraController(frontCamera, ResolutionPreset.high);
        cameraController!.initialize().then((_) {
          if (!mounted) {
            return;
          }
          setState(() {
            cameraController!.startImageStream((imageStream) {
              if (isTracking) {
                cameraImage = imageStream;
                runModel();
              }
            });
          });
        });
      } else {
        print('Front camera not found');
      }
    } else {
      print('No cameras available');
    }
  }

  void runModel() async {
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );

      String? dominantEmotionLabel;
      double maxConfidence = 0.0;

      if (predictions != null) {
        predictions.forEach((element) {
          String label = element['label'];
          double confidence = element['confidence'];

          if (confidence > maxConfidence) {
            maxConfidence = confidence;
            dominantEmotionLabel = label;
          }
        });
      }

      setState(() {
        latestPrediction = dominantEmotionLabel ?? 'Unknown';
      });

      trackedEmotions.add(latestPrediction); // Add the most dominant emotion to the tracked emotions list
    }
  }

  void loadModel() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
  }

  void startTrackingEmotion() {
    setState(() {
      isTracking = true;
      showStopButton = true;
    });
  }

  void stopTrackingEmotion() {
    setState(() {
      isTracking = false;
      showStopButton = false;
    });
    cameraController!.stopImageStream();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          dominantEmotion: latestPrediction,
          trackedEmotions: trackedEmotions,
          emotions: [],
        ),
      ),
    );
  }

  void onBackPressed() {
    widget.onBackPressed();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onBackPressed();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Emotion Tracking'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TextField(
                    controller: diaryController,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Write your diary here...',
                      border: OutlineInputBorder(),
                      suffixIcon: TextButton(
                        onPressed: () {
                          saveDiary(diaryController.text);
                          diaryController.clear();
                        },
                        child: Text('Save', style: TextStyle(color: Colors.blue)),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      startTrackingEmotion();
                    },
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(20),
                    ),
                    child: Text(
                      'Start',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  if (showStopButton) SizedBox(width: 20),
                  if (showStopButton)
                    ElevatedButton(
                      onPressed: () {
                        stopTrackingEmotion();
                      },
                      child: Text('Stop Tracking'),
                    ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SavedDiaryScreen()),
                      );
                    },
                    child: Text('Saved Diaries'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void saveDiary(String text) {
    if (text.isNotEmpty) {
      diaryRef.push().set({'text': text, 'timestamp': DateTime.now().millisecondsSinceEpoch});
      showSavedSnackbar(); // Show snackbar notification
    } else {
      showEmptyDiaryError(); // Show error snackbar for empty diary
    }
  }

  void showSavedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Diary saved'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void showEmptyDiaryError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cannot save an empty diary'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    cameraController?.dispose();
    diaryController.dispose();
    super.dispose();
  }
}

void main() {
  runApp(MaterialApp(
    home: EmotionTrackingScreen(
      onBackPressed: () {
        // Handle back button press
      },
    ),
  ));
}
