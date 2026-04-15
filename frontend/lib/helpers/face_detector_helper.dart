import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorHelper {
  static Future<bool> containsFace(String imagePath) async {
    if (kIsWeb) {
      // google_mlkit_face_detection does not support Flutter Web. 
      // Skips check on Web platform so the app doesn't crash.
      return true;
    }
    
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableLandmarks: false,
          enableClassification: false,
        ),
      );
      
      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();
      
      return faces.isNotEmpty;
    } catch (e) {
      debugPrint('Face detection error: $e');
      // Fallback to true if ML kit fails to initialize or crashes
      return true; 
    }
  }
}
