// lib/services/face_analysis_service.dart
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/material.dart';

class FaceAnalysisService {
  late FaceDetector _faceDetector;

  FaceAnalysisService() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,  // 감정 분석 활성화
        enableLandmarks: true,       // 얼굴 특징점 활성화
        enableTracking: false,       // 추적 비활성화 (사진 분석용)
        minFaceSize: 0.1,           // 최소 얼굴 크기
        performanceMode: FaceDetectorMode.accurate,  // 정확도 우선
      ),
    );
  }

  /// 얼굴을 분석하여 감정, 나이대, 특징을 추출합니다.
  Future<FaceAnalysisResult> analyzeFace(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        throw FaceAnalysisException('얼굴을 찾을 수 없습니다. 얼굴이 잘 보이는 사진을 선택해주세요.');
      }

      if (faces.length > 1) {
        // 여러 얼굴이 감지된 경우, 가장 큰 얼굴 선택
        faces.sort((a, b) => 
          (b.boundingBox.width * b.boundingBox.height)
              .compareTo(a.boundingBox.width * a.boundingBox.height)
        );
      }

      final face = faces.first;

      // 감정 분석
      final emotion = _analyzeEmotion(face);
      
      // 나이대 추정 (얼굴 특징 기반)
      final estimatedAge = _estimateAgeGroup(face);
      
      // 성격 유형 추정
      final personality = _estimatePersonality(face);

      return FaceAnalysisResult(
        emotion: emotion,
        estimatedAge: estimatedAge,
        personality: personality,
        smilingProbability: face.smilingProbability ?? 0.0,
        leftEyeOpenProbability: face.leftEyeOpenProbability ?? 0.0,
        rightEyeOpenProbability: face.rightEyeOpenProbability ?? 0.0,
        headEulerAngleY: face.headEulerAngleY ?? 0.0,
        headEulerAngleZ: face.headEulerAngleZ ?? 0.0,
        faceDetected: true,
      );
    } catch (e) {
      if (e is FaceAnalysisException) {
        rethrow;
      }
      throw FaceAnalysisException('얼굴 분석 중 오류가 발생했습니다: $e');
    }
  }

  /// 감정 분석
  EmotionType _analyzeEmotion(Face face) {
    final smiling = face.smilingProbability ?? 0.0;
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0.0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0.0;

    // 웃는 정도로 감정 판단
    if (smiling > 0.8) {
      return EmotionType.veryHappy;
    } else if (smiling > 0.6) {
      return EmotionType.happy;
    } else if (smiling > 0.4) {
      return EmotionType.neutral;
    } else if (leftEyeOpen < 0.3 || rightEyeOpen < 0.3) {
      return EmotionType.tired;
    } else {
      return EmotionType.serious;
    }
  }

  /// 나이대 추정 (간접적 - 얼굴 특징 기반)
  AgeGroup _estimateAgeGroup(Face face) {
    // ML Kit은 직접적인 나이 추정을 제공하지 않으므로
    // 얼굴 특징을 기반으로 대략적 추정
    // 실제로는 OpenAI가 더 정확하게 판단
    
    final hasLandmarks = face.landmarks.isNotEmpty;
    
    if (!hasLandmarks) {
      return AgeGroup.unknown;
    }

    // 여기서는 기본적인 추정만 수행
    // OpenAI Vision이 더 정확한 나이를 판단할 것임
    return AgeGroup.unknown;  // OpenAI에게 맡김
  }

  /// 성격 유형 추정
  PersonalityType _estimatePersonality(Face face) {
    final smiling = face.smilingProbability ?? 0.0;
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0.0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0.0;

    // 눈과 미소를 조합하여 성격 추정
    final eyesOpen = (leftEyeOpen + rightEyeOpen) / 2;

    if (smiling > 0.7 && eyesOpen > 0.8) {
      return PersonalityType.energetic;  // 활발함
    } else if (smiling > 0.5 && eyesOpen > 0.7) {
      return PersonalityType.cheerful;   // 밝음
    } else if (smiling < 0.3 && eyesOpen > 0.6) {
      return PersonalityType.serious;    // 진지함
    } else if (eyesOpen < 0.5) {
      return PersonalityType.calm;       // 차분함
    } else {
      return PersonalityType.neutral;    // 중립
    }
  }

  /// 리소스 정리
  void dispose() {
    _faceDetector.close();
  }
}

// ========== 데이터 모델 ==========

/// 얼굴 분석 결과
class FaceAnalysisResult {
  final EmotionType emotion;
  final AgeGroup estimatedAge;
  final PersonalityType personality;
  final double smilingProbability;
  final double leftEyeOpenProbability;
  final double rightEyeOpenProbability;
  final double headEulerAngleY;
  final double headEulerAngleZ;
  final bool faceDetected;

  FaceAnalysisResult({
    required this.emotion,
    required this.estimatedAge,
    required this.personality,
    required this.smilingProbability,
    required this.leftEyeOpenProbability,
    required this.rightEyeOpenProbability,
    required this.headEulerAngleY,
    required this.headEulerAngleZ,
    required this.faceDetected,
  });

  /// ML Kit 데이터를 텍스트로 변환 (OpenAI에게 전달용)
  String toPromptText() {
    return '''
ML Kit 분석 결과:
- 감정: ${emotion.korean}
- 추정 나이대: ${estimatedAge.korean}
- 성격 유형: ${personality.korean}
- 웃음 정도: ${(smilingProbability * 100).toStringAsFixed(0)}%
- 왼쪽 눈 뜨기: ${(leftEyeOpenProbability * 100).toStringAsFixed(0)}%
- 오른쪽 눈 뜨기: ${(rightEyeOpenProbability * 100).toStringAsFixed(0)}%
''';
  }

  /// 사용자에게 보여줄 간단한 요약
  String getSummary() {
    return '${emotion.korean}하고 ${personality.korean} 느낌이에요!';
  }
}

/// 감정 유형
enum EmotionType {
  veryHappy,
  happy,
  neutral,
  serious,
  tired,
}

extension EmotionTypeExtension on EmotionType {
  String get korean {
    switch (this) {
      case EmotionType.veryHappy:
        return '매우 행복';
      case EmotionType.happy:
        return '행복';
      case EmotionType.neutral:
        return '평온';
      case EmotionType.serious:
        return '진지';
      case EmotionType.tired:
        return '피곤';
    }
  }

  String get emoji {
    switch (this) {
      case EmotionType.veryHappy:
        return '😄';
      case EmotionType.happy:
        return '🙂';
      case EmotionType.neutral:
        return '😐';
      case EmotionType.serious:
        return '🤨';
      case EmotionType.tired:
        return '😴';
    }
  }
}

/// 나이대 그룹
enum AgeGroup {
  teens,      // 10대
  twenties,   // 20대
  thirties,   // 30대
  forties,    // 40대
  fifties,    // 50대 이상
  unknown,    // 알 수 없음
}

extension AgeGroupExtension on AgeGroup {
  String get korean {
    switch (this) {
      case AgeGroup.teens:
        return '10대';
      case AgeGroup.twenties:
        return '20대';
      case AgeGroup.thirties:
        return '30대';
      case AgeGroup.forties:
        return '40대';
      case AgeGroup.fifties:
        return '50대 이상';
      case AgeGroup.unknown:
        return '알 수 없음';
    }
  }
}

/// 성격 유형
enum PersonalityType {
  energetic,  // 활발
  cheerful,   // 밝음
  serious,    // 진지
  calm,       // 차분
  neutral,    // 중립
}

extension PersonalityTypeExtension on PersonalityType {
  String get korean {
    switch (this) {
      case PersonalityType.energetic:
        return '활발';
      case PersonalityType.cheerful:
        return '밝음';
      case PersonalityType.serious:
        return '진지';
      case PersonalityType.calm:
        return '차분';
      case PersonalityType.neutral:
        return '중립';
    }
  }
}

/// 얼굴 분석 예외
class FaceAnalysisException implements Exception {
  final String message;
  FaceAnalysisException(this.message);

  @override
  String toString() => message;
}