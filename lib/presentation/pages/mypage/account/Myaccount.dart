import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pet_moment/presentation/pages/mypage/account/Changepassword.dart';
import 'package:pet_moment/presentation/pages/mypage/account/changeProfile.dart';
import 'package:pet_moment/presentation/pages/mypage/account/withdraw.dart';
import 'package:pet_moment/presentation/pages/shop/AddressSave.dart';

class Myaccount extends StatelessWidget {
  const Myaccount({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: const Text(
          '계정설정',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _MenuItem(
                icon: Icons.navigate_next,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyEmail(),
                    ),
                  );
                },
                text: '이메일'),
            _MenuItem(
                icon: Icons.navigate_next,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SavedAddressesScreen()),
                  );
                },
                text: '배송지 관리'),
            const Divider(height: 1),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.all(9.0),
                child: Text(
                  '계정정보',
                  style: TextStyle(fontSize: 13, color: Colors.black),
                ),
              ),
            ),
            _MenuItem(
                icon: Icons.navigate_next,
                onTap: () async {
                  final profileUpdated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ChangeProfile()),
                  );

                  if (profileUpdated == true) {
                    Navigator.pop(context, true);
                  }
                },
                text: '프로필 변경'),
            _MenuItem(
                icon: Icons.navigate_next,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ChangePassword()),
                  );
                },
                text: '계정 비밀번호 변경'),
            _MenuItem(
                icon: Icons.navigate_next,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WithdrawPage()),
                  );
                },
                text: '계정탈퇴')
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.text,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(
        text,
        style: const TextStyle(fontSize: 17, color: Colors.black),
      ),
      title: const Text(''),
      trailing: Icon(icon),
      onTap: onTap ?? () {},
    );
  }
}

class MyEmail extends StatelessWidget {
  const MyEmail({super.key});

  /// Firestore에서 현재 사용자의 문서를 Future로 가져오는 함수
  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserDoc() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
    } else {
      throw Exception("User not logged in");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Padding(
          padding: EdgeInsets.only(right: 220),
          child: Text(
            '계정설정',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _getUserDoc(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("사용자 정보를 불러올 수 없습니다."));
          }

          final userData = snapshot.data!.data();
          final email = userData?['email'] ?? 'Anonymous';

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(10.0),
                child: Text(
                  '이메일',
                  style: TextStyle(color: Color(0xffD2D2D2)),
                  textAlign: TextAlign.left,
                ),
              ),
              ListTile(
                leading: Container(
                  width: 63,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE94A39),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Text(
                      '대표',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                title: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    email,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
            ],
          );
        },
      ),
    );
  }
}
