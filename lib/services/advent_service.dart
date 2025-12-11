import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/advent_mission.dart';

class AdventService {
  static const String _missionCompletedKeyPrefix = 'mission_completed_';

  // 모든 미션 데이터를 불러오고 완료 상태를 적용
  Future<List<AdventMission>> getMissions() async {
    // 1. JSON 파일에서 미션 목록 로드
    final String response = await rootBundle.loadString('assets/data/missions.json');
    final data = await json.decode(response);
    final List<dynamic> missionListJson = data['missions'];

    List<AdventMission> missions = missionListJson
        .map((json) => AdventMission.fromJson(json))
        .toList();

    // 2. SharedPreferences에서 각 미션의 완료 상태 로드
    final prefs = await SharedPreferences.getInstance();
    for (var mission in missions) {
      mission.isCompleted = prefs.getBool(_getMissionKey(mission.day)) ?? false;
    }

    return missions;
  }

  // 특정 날짜의 미션을 완료로 표시
  Future<void> completeMission(int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_getMissionKey(day), true);
  }

  // 완료된 미션 개수 가져오기
  Future<int> getCompletedMissionCount() async {
    final missions = await getMissions();
    return missions.where((m) => m.isCompleted).length;
  }

  // 모든 미션 진행도 리셋 (테스트용)
  Future<void> resetAllMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final missions = await getMissions();
    for (var mission in missions) {
      await prefs.remove(_getMissionKey(mission.day));
    }
  }

  // SharedPreferences 키 생성
  String _getMissionKey(int day) {
    return '$_missionCompletedKeyPrefix$day';
  }
}