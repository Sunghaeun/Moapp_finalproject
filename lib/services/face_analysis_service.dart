// lib/services/face_analysis_service.dart
import 'dart:io';
import 'dart:math';
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
  final String detectedEmotion;
  final double confidenceScore;
  final Map<String, double> ageConfidence;
  final List<String> personalityTraits;
  final Map<String, dynamic> detailedAnalysis;

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
    required this.ageConfidence,
    required this.personalityTraits,
    required this.detailedAnalysis,
  });

  String getPersonalityDescription() {
    if (personalityTraits.isEmpty) return '균형 잡힌 성격';
    return personalityTraits.take(3).join(', ');
  }

  String getGiftRecommendationHint() {
    List<String> hints = [];
    
    if (detectedEmotion == 'Very Happy' || detectedEmotion == 'Happy') {
      hints.add('활발하고 밝은 성격이시네요! 재미있고 감각적인 선물이 좋겠어요.');
    } else if (detectedEmotion == 'Calm' || detectedEmotion == 'Neutral') {
      hints.add('차분하고 안정적인 분위기시네요. 실용적이고 세련된 선물이 어울려요.');
    } else if (detectedEmotion == 'Serious') {
      hints.add('진지하고 사려 깊은 성격이시네요. 의미 있고 고급스러운 선물이 좋겠어요.');
    } else if (detectedEmotion == 'Angry') {
      hints.add('스트레스를 풀어줄 수 있는 힐링 선물이 필요해 보여요.');
    } else if (detectedEmotion == 'Sad') {
      hints.add('따뜻하고 위로가 되는 선물이 필요해 보여요.');
    } else {
      hints.add('편안하고 실용적인 선물이 좋겠어요.');
    }
    
    final ageNum = int.tryParse(estimatedAge.replaceAll(RegExp(r'[^0-9]'), ''));
    if (ageNum != null) {
      if (ageNum < 20) {
        hints.add('트렌디하고 개성 넘치는 아이템을 추천드려요.');
      } else if (ageNum < 30) {
        hints.add('실용적이면서도 스타일리시한 아이템이 인기예요.');
      } else if (ageNum < 40) {
        hints.add('품격 있고 고급스러운 아이템을 추천드려요.');
      } else if (ageNum < 50) {
        hints.add('클래식하면서도 실용적인 아이템이 좋겠어요.');
      } else {
        hints.add('의미 있고 건강을 생각하는 아이템을 추천드려요.');
      }
    }
    
    return hints.join(' ');
  }

  String getEmotionEmoji() {
    switch (detectedEmotion) {
      case 'Very Happy':
        return '😄';
      case 'Happy':
        return '😊';
      case 'Calm':
        return '😌';
      case 'Neutral':
        return '😐';
      case 'Serious':
        return '🤔';
      case 'Angry':
        return '😠';
      case 'Sad':
        return '😔';
      case 'Tired':
        return '😪';
      default:
        return '🙂';
    }
  }

  String getMostLikelyAge() {
    if (ageConfidence.isEmpty) return estimatedAge;
    final sorted = ageConfidence.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
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
      minFaceSize: 0.15,
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
      print('=== 고급 얼굴 분석 시작 ===');
      
      final inputImage = InputImage.fromFilePath(imagePath);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        print('❌ 얼굴을 찾을 수 없습니다');
        return null;
      }

      final face = faces.reduce((curr, next) {
        final currSize = curr.boundingBox.width * curr.boundingBox.height;
        final nextSize = next.boundingBox.width * next.boundingBox.height;
        return currSize > nextSize ? curr : next;
      });

      final emotionData = _analyzeEmotionAdvanced(face);
      final ageData = _estimateAgeAdvanced(face);
      final personalityTraits = _analyzePersonality(face, emotionData);
      final gender = _estimateGenderAdvanced(face);
      final mood = _analyzeMoodAdvanced(face, emotionData);

      final smileProbability = face.smilingProbability ?? 0.0;
      final isSmiling = smileProbability > 0.5;
      final leftEyeOpen = (face.leftEyeOpenProbability ?? 1.0) > 0.5;
      final rightEyeOpen = (face.rightEyeOpenProbability ?? 1.0) > 0.5;

      print('=== 분석 완료 ===');
      print('감정: ${emotionData['emotion']} (${(emotionData['confidence'] * 100).toStringAsFixed(1)}%)');
      print('추정 연령: ${ageData['primaryAge']} (신뢰도: ${(ageData['confidence'] * 100).toStringAsFixed(1)}%)');
      print('성격 특성: ${personalityTraits.join(", ")}');
      print('성별: $gender');

      return FaceAnalysisResult(
        isSmiling: isSmiling,
        smileProbability: smileProbability,
        leftEyeOpen: leftEyeOpen,
        rightEyeOpen: rightEyeOpen,
        estimatedAge: ageData['primaryAge'],
        estimatedGender: gender,
        mood: mood,
        detectedEmotion: emotionData['emotion'],
        confidenceScore: emotionData['confidence'],
        ageConfidence: ageData['ageConfidence'],
        personalityTraits: personalityTraits,
        detailedAnalysis: {
          'faceSize': face.boundingBox.width * face.boundingBox.height,
          'headAngle': {
            'y': face.headEulerAngleY ?? 0,
            'z': face.headEulerAngleZ ?? 0,
          },
          'landmarks': face.landmarks.length,
          'contours': face.contours.length,
        },
      );
    } catch (e) {
      print('❌ 얼굴 분석 오류: $e');
      return null;
    }
  }

  Map<String, dynamic> _analyzeEmotionAdvanced(Face face) {
    final smileProb = face.smilingProbability ?? 0.0;
    final leftEyeProb = face.leftEyeOpenProbability ?? 1.0;
    final rightEyeProb = face.rightEyeOpenProbability ?? 1.0;
    final avgEyeOpen = (leftEyeProb + rightEyeProb) / 2;
    
    final headY = (face.headEulerAngleY ?? 0).abs();
    final headZ = (face.headEulerAngleZ ?? 0).abs();
    final isFrontal = headY < 15 && headZ < 15;
    
    // 눈썹과 입 위치로 화남 감지
    bool possiblyAngry = false;
    final landmarks = face.landmarks;
    final leftEye = landmarks[FaceLandmarkType.leftEye];
    final mouth = landmarks[FaceLandmarkType.bottomMouth];

    // 눈과 입 랜드마크가 모두 존재할 때만 비율 계산
    if (leftEye != null && mouth != null) {
      final leftEyeY = leftEye.position.y;
      final mouthY = mouth.position.y;

      // 얼굴 크기 대비 눈-입 거리가 짧으면 (눈썹 찌푸림) 화남 가능성
      // BoundingBox 높이가 0인 경우를 방지
      if (face.boundingBox.height > 0) {
        final eyeToMouthRatio = (mouthY - leftEyeY) / face.boundingBox.height;
        // 눈과 입 사이의 거리가 얼굴 높이의 35% 미만이면 화난 표정으로 간주
        if (eyeToMouthRatio < 0.35) {  // 평균보다 짧으면
          possiblyAngry = true;
        }
      }
    }
    
    String emotion;
    double confidence;
    
    // 화남 감지 (미소 없음 + 눈 크게 뜸 + 정면 + 랜드마크 분석)
    if (possiblyAngry && smileProb < 0.2 && avgEyeOpen > 0.7 && isFrontal) {
      emotion = 'Angry';
      confidence = 0.7 + (1.0 - smileProb) * 0.2;
    }
    // 매우 행복
    else if (smileProb > 0.8 && avgEyeOpen > 0.7) {
      emotion = 'Very Happy';
      confidence = smileProb * 0.7 + avgEyeOpen * 0.3;
    }
    // 행복
    else if (smileProb > 0.5) {
      emotion = 'Happy';
      confidence = smileProb * 0.8 + avgEyeOpen * 0.2;
    }
    // 차분함
    else if (smileProb > 0.3 && avgEyeOpen > 0.6) {
      emotion = 'Calm';
      confidence = 0.6 + (smileProb * 0.2) + (avgEyeOpen * 0.2);
    }
    // 중립
    else if (smileProb > 0.15 && smileProb <= 0.3) {
      emotion = 'Neutral';
      confidence = 0.5 + (smileProb * 0.3);
    }
    // 피곤함
    else if (avgEyeOpen < 0.5) {
      emotion = 'Tired';
      confidence = 1.0 - avgEyeOpen;
    }
    // 진지함 또는 슬픔
    else if (smileProb < 0.1 && isFrontal) {
      // 눈이 거의 감겼으면 슬픔, 아니면 진지함
      if (avgEyeOpen < 0.6) {
        emotion = 'Sad';
        confidence = 0.6 + (1.0 - avgEyeOpen) * 0.2;
      } else {
        emotion = 'Serious';
        confidence = 0.6;
      }
    }
    else {
      emotion = 'Neutral';
      confidence = 0.5;
    }
    
    return {
      'emotion': emotion,
      'confidence': confidence,
      'smile': smileProb,
      'eyeOpen': avgEyeOpen,
    };
  }

  Map<String, dynamic> _estimateAgeAdvanced(Face face) {
    final boundingBox = face.boundingBox;
    final faceWidth = boundingBox.width;
    final faceHeight = boundingBox.height;
    final faceSize = faceWidth * faceHeight;
    final aspectRatio = faceHeight / faceWidth;
    
    final landmarks = face.landmarks;
    final hasDetailedLandmarks = landmarks.length >= 5;
    
    final contours = face.contours;
    final hasContours = contours.isNotEmpty;
    
    Map<String, double> ageScores = {
      '10대': 0.0,
      '20대': 0.0,
      '30대': 0.0,
      '40대': 0.0,
      '50대 이상': 0.0,
    };
    
    if (faceSize < 35000) {
      ageScores['10대'] = ageScores['10대']! + 0.4;
      ageScores['20대'] = ageScores['20대']! + 0.2;
    } else if (faceSize < 55000) {
      ageScores['20대'] = ageScores['20대']! + 0.4;
      ageScores['10대'] = ageScores['10대']! + 0.2;
      ageScores['30대'] = ageScores['30대']! + 0.2;
    } else if (faceSize < 80000) {
      ageScores['30대'] = ageScores['30대']! + 0.4;
      ageScores['20대'] = ageScores['20대']! + 0.2;
      ageScores['40대'] = ageScores['40대']! + 0.2;
    } else if (faceSize < 110000) {
      ageScores['40대'] = ageScores['40대']! + 0.4;
      ageScores['30대'] = ageScores['30대']! + 0.2;
      ageScores['50대 이상'] = ageScores['50대 이상']! + 0.2;
    } else {
      ageScores['50대 이상'] = ageScores['50대 이상']! + 0.5;
      ageScores['40대'] = ageScores['40대']! + 0.2;
    }
    
    if (aspectRatio > 1.35) {
      ageScores['10대'] = ageScores['10대']! + 0.2;
      ageScores['20대'] = ageScores['20대']! + 0.1;
    } else if (aspectRatio < 1.25) {
      ageScores['40대'] = ageScores['40대']! + 0.1;
      ageScores['50대 이상'] = ageScores['50대 이상']! + 0.1;
    }
    
    if (hasDetailedLandmarks) {
      if (landmarks.length > 8) {
        ageScores['30대'] = ageScores['30대']! + 0.1;
        ageScores['40대'] = ageScores['40대']! + 0.1;
        ageScores['50대 이상'] = ageScores['50대 이상']! + 0.1;
      }
    }
    
    final smileProb = face.smilingProbability ?? 0.5;
    if (smileProb > 0.7) {
      ageScores['10대'] = ageScores['10대']! + 0.1;
      ageScores['20대'] = ageScores['20대']! + 0.1;
    }
    
    final totalScore = ageScores.values.reduce((a, b) => a + b);
    if (totalScore > 0) {
      ageScores.updateAll((key, value) => value / totalScore);
    }
    
    final sortedAges = ageScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final primaryAge = sortedAges.first.key;
    final confidence = sortedAges.first.value;
    
    return {
      'primaryAge': primaryAge,
      'confidence': confidence,
      'ageConfidence': ageScores,
    };
  }

  List<String> _analyzePersonality(Face face, Map<String, dynamic> emotionData) {
    List<String> traits = [];
    
    final emotion = emotionData['emotion'] as String;
    final smileProb = emotionData['smile'] as double;
    final eyeOpen = emotionData['eyeOpen'] as double;
    
    if (emotion == 'Very Happy') {
      traits.add('매우 긍정적');
      traits.add('외향적');
    } else if (emotion == 'Happy') {
      traits.add('밝고 활발함');
      traits.add('사교적');
    } else if (emotion == 'Calm') {
      traits.add('차분함');
      traits.add('안정적');
    } else if (emotion == 'Serious') {
      traits.add('진지함');
      traits.add('신중함');
    } else if (emotion == 'Angry') {
      traits.add('강인함');
      traits.add('열정적');
    } else if (emotion == 'Sad') {
      traits.add('감성적');
      traits.add('섬세함');
    } else if (emotion == 'Neutral') {
      traits.add('균형잡힌');
    } else {
      traits.add('안정적');
    }
    
    if (eyeOpen > 0.8) {
      if (!traits.contains('활기찬')) traits.add('활기찬');
    } else if (eyeOpen < 0.6) {
      if (!traits.contains('편안한')) traits.add('편안한');
    }
    
    final headY = (face.headEulerAngleY ?? 0).abs();
    if (headY < 10) {
      if (!traits.contains('정직함') && traits.length < 3) traits.add('정직함');
    }
    
    if (traits.isEmpty) {
      traits.add('균형잡힌');
    }
    
    return traits.take(3).toList();
  }

  String _estimateGenderAdvanced(Face face) {
    final aspectRatio = face.boundingBox.height / face.boundingBox.width;
    
    if (aspectRatio > 1.32) {
      return '여성';
    } else if (aspectRatio < 1.28) {
      return '남성';
    } else {
      return '모두에게';
    }
  }

  String _analyzeMoodAdvanced(Face face, Map<String, dynamic> emotionData) {
    final emotion = emotionData['emotion'] as String;
    final confidence = emotionData['confidence'] as double;
    
    if (confidence < 0.5) {
      return '복합적인';
    }
    
    switch (emotion) {
      case 'Very Happy':
        return '매우 행복한';
      case 'Happy':
        return '밝은';
      case 'Calm':
        return '차분한';
      case 'Neutral':
        return '평온한';
      case 'Serious':
        return '진지한';
      case 'Angry':
        return '강렬한';
      case 'Sad':
        return '우울한';
      case 'Tired':
        return '편안한';
      default:
        return '자연스러운';
    }
  }

  void dispose() {
    _faceDetector.close();
  }
}