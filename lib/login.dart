import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Firebase & GoogleSignIn 인스턴스
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

   // 🔥 Firestore 인스턴스
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -----------------------------
  // ⭐ uid로 user 문서를 만들어주는 함수
  // -----------------------------
  Future<void> _createUserDocIfFirstTime(User user) async {
    final docRef = _db.collection('user').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      // Google 계정 정보
      final name = user.displayName ?? 'Unknown';
      final email = user.email ?? '';

      await docRef.set({
        'name': name,
        'email': email,
        'uid': user.uid,
        'status_message': 'I promise to take the test honestly before GOD.',
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ 더 안전한 구글 로그인 로직
  Future<void> _signInWithGoogle() async {
    try {
      // 🔄 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // 1. 구글 계정 선택 UI 표시
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // 👉 사용자가 취소했으면 다이얼로그 닫고 종료
      if (googleUser == null) {
        if (mounted) Navigator.of(context).pop();
        print('사용자가 구글 로그인을 취소했습니다.');
        return;
      }

      // 2. 인증 정보 받아오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Firebase용 Credential 만들기
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Firebase에 로그인
      final UserCredential userCred =
          await _auth.signInWithCredential(credential);
      final User? user = userCred.user;

      // 로딩 다이얼로그 닫기
      if (mounted) Navigator.of(context).pop();

      if (!mounted || user == null) {
        print('Firebase 로그인 후 user가 null 입니다.');
        return;
      }

      // 5. 🔥 Firestore에 user 문서 생성 (처음 로그인 시에만)
      await _createUserDocIfFirstTime(user);

      // 6. 홈 화면으로 이동
      //  👉 app.dart에서 HomePage가 매핑된 라우트 이름으로 맞춰줘야 함!
      Navigator.pushReplacementNamed(context, '/home');

    } catch (e) {
      // 에러 시 로딩 다이얼로그가 열려있으면 닫기
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      print('Google sign-in error: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인 오류: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

    // ⭐ 게스트(Anonymous) 로그인 + Firestore user 문서 생성
  Future<void> _signInAsGuest() async {
    try {
      // 로딩 다이얼로그
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // 1. Firebase 익명 로그인
      final UserCredential userCred = await _auth.signInAnonymously();
      final User? user = userCred.user;

      // 로딩 닫기
      if (mounted) Navigator.of(context).pop();

      if (user == null) {
        print('Anonymous user is null');
        return;
      }

      // 2. Firestore에 user 문서 생성 (uid, status_message만)
      final docRef = _db.collection('user').doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'uid': user.uid,
          'status_message':
              'I promise to take the test honestly before GOD.',
        });
      }

      // 3. 홈으로 이동
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');

    } catch (e) {
      // 에러 시 로딩 닫기
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      print('Anonymous sign-in error: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('게스트 로그인 오류: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          children: <Widget>[
            const SizedBox(height: 200.0),
            Column(
              children: <Widget>[
                Image.asset('assets/diamond.png'),
                const SizedBox(height: 16.0),
                const Text(
                  'SHRINE',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 120.0),

            // // 기존 Username / Password
            // TextField(
            //   controller: _usernameController,
            //   decoration: const InputDecoration(
            //     filled: true,
            //     labelText: 'Username',
            //   ),
            // ),
            // const SizedBox(height: 12.0),
            // TextField(
            //   controller: _passwordController,
            //   decoration: const InputDecoration(
            //     filled: true,
            //     labelText: 'Password',
            //   ),
            //   obscureText: true,
            // ),
            // const SizedBox(height: 12.0),

            // // 기존 버튼들 (CANCEL / NEXT)
            // OverflowBar(
            //   alignment: MainAxisAlignment.end,
            //   children: <Widget>[
            //     TextButton(
            //       child: const Text('CANCEL'),
            //       onPressed: () {
            //         _usernameController.clear();
            //         _passwordController.clear();
            //       },
            //     ),
            //     ElevatedButton(
            //       child: const Text('NEXT'),
            //       onPressed: () {
            //         // 간단한 로그인 (실제로는 검증 로직 필요)
            //         Navigator.pushReplacementNamed(context, '/');
            //       },
            //     ),
            //   ],
            // ),

            // const SizedBox(height: 40.0),
            
            // // 구분선
            // const Row(
            //   children: <Widget>[
            //     Expanded(child: Divider()),
            //     Padding(
            //       padding: EdgeInsets.symmetric(horizontal: 16.0),
            //       child: Text('OR'),
            //     ),
            //     Expanded(child: Divider()),
            //   ],
            // ),

            const SizedBox(height: 24.0),

            // ✅ 구글 로그인 버튼
            SizedBox(
              width: double.infinity,
              height: 48.0,
              child: ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon: const Icon(Icons.login, color: Colors.white),
                label: const Text(
                  'Google',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            // 게스트
            SizedBox(
              width: double.infinity,
              height: 48.0,
              child: ElevatedButton.icon(
                onPressed: _signInAsGuest,
                icon: const Icon(Icons.login, color: Colors.white),
                label: const Text(
                  'Guest',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 103, 103, 103),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
