import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/advent_mission.dart';

class AdventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// 새 사용자를 위해 Firestore에 초기 미션 데이터를 생성합니다.
  /// 트랜잭션의 일부로 실행됩니다.
  Future<void> initializeMissionsForUser(String uid,
      {required Transaction transaction}) async {
    final String response = await rootBundle.loadString('assets/data/missions.json');
    final data = await json.decode(response);
    final List<dynamic> missionListJson = data['missions'];

    final userMissionsRef =
        _firestore.collection('users').doc(uid).collection('advent_missions');

    for (var missionJson in missionListJson) {
      final mission = AdventMission.fromJson(missionJson);
      final missionDocRef = userMissionsRef.doc(mission.day.toString());
      transaction.set(missionDocRef, mission.toJson());
    }
  }

  // Firestore에서 사용자의 모든 미션 데이터를 불러옵니다.
  Future<List<AdventMission>> getMissions() async {
    if (_uid == null) throw Exception('사용자가 로그인되어 있지 않습니다.');

    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('advent_missions')
        .orderBy('day')
        .get();

    if (snapshot.docs.isEmpty) {
      // 데이터가 없는 경우 (매우 드문 경우), 초기화를 시도할 수 있습니다.
      // 여기서는 빈 리스트를 반환하거나 에러 처리를 할 수 있습니다.
      print('경고: Firestore에 어드벤트 미션 데이터가 없습니다. uid: $_uid');
      return [];
    }

    final missions = snapshot.docs
        .map((doc) => AdventMission.fromJson(doc.data()))
        .toList();

    return missions;
  }

  // Firestore에서 특정 날짜의 미션을 완료로 표시합니다.
  Future<void> completeMission(int day) async {
    if (_uid == null) throw Exception('사용자가 로그인되어 있지 않습니다.');

    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('advent_missions')
        .doc(day.toString())
        .update({'isCompleted': true});
  }

  // Firestore에서 완료된 미션 개수를 가져옵니다.
  Future<int> getCompletedMissionCount() async {
    if (_uid == null) return 0;

    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('advent_missions')
        .where('isCompleted', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }
}