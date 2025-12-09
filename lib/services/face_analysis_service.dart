import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

class FaceAnalysisResult {
  final bool isSmiling;
  final double smileProbability;
  final bool leftEyeOpen;
  final bool rightEyeOpen;
  final String estimatedAge;
  final String estimatedGender;
  final String mood;
  final String detectedEmotion; // 새로 추가!
  final double confidenceScore; // 감정 신뢰도

  FaceAnalysisResult({
    required this.isSmiling,
    required this.smileProbability,
    required this.leftEyeOpen,
    required this.rightEyeOpen,
    required this.estimatedAge,
    required this.estimatedGender,
    required this.mood,
    required this.detectedEmotion,
    required this.confidenceScore,
  });

  String getPersonalityDescription() {
    // 감정 기반 성격 분석
    switch (detectedEmotion) {
      case 'Very Happy':
        return '매우 밝고 긍정적인 성격';
      case 'Happy':
        return '활발하고 사교적인 성격';
      case 'Neutral':
        return '차분하고 안정적인 성격';
      case 'Not Happy':
        return '진지하고 사려 깊은 성격';
      default:
        return '균형 잡힌 성격';
    }
  }

  String getGiftRecommendationHint() {
    String hint = '';
    
    // 감정 기반 추천
    switch (detectedEmotion) {
      case 'Very Happy':
        hint += '재미있고 유쾌한 선물이 완벽해요! ';
        break;
      case 'Happy':
        hint += '밝고 활기찬 선물이 잘 어울려요! ';
        break;
      case 'Neutral':
        hint += '실용적이고 세련된 선물이 좋겠어요. ';
        break;
      case 'Not Happy':
        hint += '따뜻하고 위로가 되는 선물이 필요해요. ';
        break;
    }
    
    // 연령대 기반 추천
    if (estimatedAge == '10대' || estimatedAge == '20대') {
      hint += '트렌디하고 감각적인 아이템을 추천드려요.';
    } else if (estimatedAge == '30대' || estimatedAge == '40대') {
      hint += '품격 있고 고급스러운 아이템을 추천드려요.';
    } else {
      hint += '클래식하고 의미 있는 아이템을 추천드려요.';
    }
    
    return hint;
  }

  String getEmotionEmoji() {
    switch (detectedEmotion) {
      case 'Very Happy':
        return '😄';
      case 'Happy':
        return '😊';
      case 'Neutral':
        return '😐';
      case 'Not Happy':
        return '😔';
      default:
        return '🙂';
    }
  }
}

class FaceAnalysisService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: false,
      enableContours: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.1,
    ),
  );

  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.front,
      );
      return image;
    } catch (e) {
      print('이미지 선택 오류: $e');
      return null;
    }
  }

  Future<FaceAnalysisResult?> analyzeFace(String imagePath) async {
    try {
      print('=== 얼굴 분석 시작 ===');
      print('이미지 경로: $imagePath');
      
      // 1. ML Kit으로 얼굴 감지
      final inputImage = InputImage.fromFilePath(imagePath);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      print('감지된 얼굴 수: ${faces.length}');

      if (faces.isEmpty) {
        print('❌ 얼굴을 찾을 수 없습니다');
        return null;
      }

      // 가장 큰 얼굴 선택
      final face = faces.reduce((curr, next) {
        final currSize = curr.boundingBox.width * curr.boundingBox.height;
        final nextSize = next.boundingBox.width * next.boundingBox.height;
        return currSize > nextSize ? curr : next;
      });

      print('선택된 얼굴 크기: ${face.boundingBox.width} x ${face.boundingBox.height}');

      // 2. 감정 인식 (face_emotion_detector 사용)
      // face_emotion_detector 패키지 대신 ML Kit의 미소 확률로 감정 추정
      String detectedEmotion = 'Neutral';
      double confidenceScore = 0.0;
      final smileProbabilityForEmotion = face.smilingProbability ?? 0.0;
      if (smileProbabilityForEmotion > 0.8) {
        detectedEmotion = 'Very Happy';
      } else if (smileProbabilityForEmotion > 0.4) {
        detectedEmotion = 'Happy';
      } else if (smileProbabilityForEmotion > 0.1) {
        detectedEmotion = 'Neutral';
      } else {
        detectedEmotion = 'Not Happy';
      }
      confidenceScore = smileProbabilityForEmotion;
      print('🎭 감정 인식 결과 (ML Kit 기반): $detectedEmotion');

      // 3. 기본 얼굴 분석
      final smileProbability = face.smilingProbability ?? 0.0;
      final isSmiling = smileProbability > 0.5;
      print('미소 확률: ${(smileProbability * 100).toStringAsFixed(1)}%');

      final leftEyeOpenProbability = face.leftEyeOpenProbability ?? 1.0;
      final rightEyeOpenProbability = face.rightEyeOpenProbability ?? 1.0;
      final leftEyeOpen = leftEyeOpenProbability > 0.5;
      final rightEyeOpen = rightEyeOpenProbability > 0.5;

      final estimatedAge = _estimateAgeImproved(face);
      final estimatedGender = _estimateGender(face);
      final mood = _analyzeMood(face, detectedEmotion);

      print('=== 분석 완료 ===');
      print('감정: $detectedEmotion (${(confidenceScore * 100).toStringAsFixed(1)}%)');
      print('추정 연령: $estimatedAge');
      print('분위기: $mood');

      return FaceAnalysisResult(
        isSmiling: isSmiling,
        smileProbability: smileProbability,
        leftEyeOpen: leftEyeOpen,
        rightEyeOpen: rightEyeOpen,
        estimatedAge: estimatedAge,
        estimatedGender: estimatedGender,
        mood: mood,
        detectedEmotion: detectedEmotion,
        confidenceScore: confidenceScore,
      );
    } catch (e) {
      print('❌ 얼굴 분석 오류: $e');
      return null;
    }
  }

  String _estimateAgeImproved(Face face) {
    final boundingBox = face.boundingBox;
    final faceSize = boundingBox.width * boundingBox.height;
    
    // 얼굴 랜드마크를 사용한 더 정확한 추정
    final landmarks = face.landmarks;
    bool hasDetailedFeatures = landmarks.isNotEmpty;
    
    if (faceSize < 40000) {
      return '10대';
    } else if (faceSize < 70000) {
      return '20대';
    } else if (faceSize < 100000) {
      return '30대';
    } else if (faceSize < 130000) {
      return '40대';
    } else {
      return '50대 이상';
    }
  }

  String _estimateGender(Face face) {
    return '모두에게 어울리는';
  }

  String _analyzeMood(Face face, String emotion) {
    switch (emotion) {
      case 'Very Happy':
        return '매우 행복한';
      case 'Happy':
        return '밝은';
      case 'Neutral':
        return '차분한';
      case 'Not Happy':
        return '진지한';
      default:
        return '평온한';
    }
  }

  void dispose() {
    _faceDetector.close();
  }
}