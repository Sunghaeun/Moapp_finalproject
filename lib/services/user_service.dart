import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'users';

  /// 사용자가 처음 로그인할 때 Firestore에 사용자 정보를 저장합니다.
  /// 문서가 이미 존재하면 마지막 로그인 시간만 업데이트합니다.
  Future<void> saveUser(User user) async {
    final userRef = _firestore.collection(_collectionPath).doc(user.uid);
    final doc = await userRef.get();

    final userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? '게스트',
      'photoURL': user.photoURL,
      'isAnonymous': user.isAnonymous,
      'lastLogin': FieldValue.serverTimestamp(),
    };

    if (!doc.exists) {
      // 새 사용자일 경우, 생성 시간 추가
      userData['createdAt'] = FieldValue.serverTimestamp();
      await userRef.set(userData);
      print('새로운 사용자 정보를 저장했습니다: ${user.uid}');
    } else {
      // 기존 사용자일 경우, 마지막 로그인 시간만 업데이트
      await userRef.update({
        'lastLogin': FieldValue.serverTimestamp(),
        // 필요한 경우 displayName이나 photoURL 등도 업데이트 할 수 있습니다.
        'displayName': user.displayName ?? doc.data()?['displayName'] ?? '게스트',
        'photoURL': user.photoURL ?? doc.data()?['photoURL'],
      });
      print('기존 사용자 정보를 업데이트했습니다: ${user.uid}');
    }
  }

  /// Firestore에서 사용자 정보를 가져옵니다.
  Future<DocumentSnapshot?> getUser(String uid) {
    return _firestore.collection(_collectionPath).doc(uid).get();
  }
}